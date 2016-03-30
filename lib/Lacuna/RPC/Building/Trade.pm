package Lacuna::RPC::Building::Trade;

use Moose;
use feature "switch";
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';
use Guard;
use List::Util qw(first);
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES SHIP_WASTE_TYPES SHIP_TRADE_TYPES);

with 'Lacuna::Role::TraderRpc','Lacuna::Role::Fleet::Trade','Lacuna::Role::Navigation';

sub app_url {
    return '/trade';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Trade';
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;

    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id, skip_offline => 1 });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;

    my $out = $orig->($self, $session, $building);

    my $bodies = Lacuna->db->resultset('Map::Body')->
        search(
               {
                   # if we add this in, mysql gets really confused and slow.
                   #'me.id' => { '!=' => $session->current_body->id },
                   -or => [
                           {  'me.empire_id'   => $empire->id },
                           ({ 'me.alliance_id' => $empire->alliance_id }) x!! $empire->alliance_id,
                          ]
               }, { order_by => 'me.name' }
              );

    my (@colonies,@stations);

    while (my $body = $bodies->next)
    {
        next if $body->id == $session->current_body->id;

        my $info = {
            name => $body->name,
            id   => $body->id,
            x    => $body->x,
            y    => $body->y, #,,,
            zone => $body->zone,
        };
        if ($body->get_type eq 'space station') {
            push @stations, $info;
        }
        else {
            push @colonies, $info;
        }
    }
    $out->{transport}{pushable} = [ @colonies, @stations ];

    return $out;
};

sub accept_from_market {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
            trade_id        => shift,
        };
    }

    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});
    my $trade_id    = $args->{trade_id};

    if (not $trade_id) {
        confess [1002, 'You have not specified a trade to accept.'];
    }
    my $cache = Lacuna->cache;
    if (! $cache->add('trade_lock', $trade_id, 1, 5)) {
        confess [1013, 'Another buyer has placed an offer on this trade. Please wait a few moments and try again.'];
    }
    my $guard = guard {
        $cache->delete('trade_lock',$trade_id);
    };

    if ($building->level < 1) {
        confess [1013, 'You cannot use a trade ministry that has not yet been built.'];
    }

    $empire->current_session->check_captcha;

    my $trade = $building->market->find($trade_id);
    if (not defined $trade) {
        confess [1002, 'Could not find that trade. Perhaps it has already been accepted.',$trade_id];
    }
    my $offer_fleet = Lacuna->db->resultset('Fleet')->find($trade->fleet_id);
    if (not defined $offer_fleet) {
        $trade->withdraw;
        confess [1009, 'Trade no longer available.'];
    }

    my $body = $building->body;
    if ($empire->essentia < $trade->ask) {
        confess [1011, 'You need at least '.$trade->ask.' essentia to make this trade.']
    }

    $self->check_payload_fleet_id($trade->payload->{fleets}, $body);

    $guard->cancel;

    $empire->spend_essentia($trade->ask, 'Trade Price', 0, $trade->body->empire->id, $trade->body->empire->name )->update;
    $trade->body->empire->add_essentia($trade->ask, 'Trade Income', 0, $empire->id, $empire->name)->update;
    
    $offer_fleet->send(
        target  => $body,
        payload => $trade->payload,
    );
    
    $trade->body->empire->send_predefined_message(
        tags        => ['Trade','Alert'],
        filename    => 'trade_accepted.txt',
        params      => [join("; ",@{$trade->format_description_of_payload}), $trade->ask.' essentia', $empire->id, $empire->name],
    );
    $trade->delete;

    return {
        status      => $self->format_status($empire, $building->body),
    };
}


sub add_fleet_to_supply_duty {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
            fleet_id        => shift,
        };
    }

    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});
    my $fleet_id    = $args->{fleet_id};
    my $session     = $self->get_session($args);

    if (not defined $building) {
        confess [1002, "Building not found."];
    }
    my $fleet = Lacune->db->resultset('Fleet')->find($fleet_id);
    if (not defined $fleet) {
        confess [1002, "Fleet not found."];
    }
    if ($fleet->task ne 'Docked') {
        confess [1009, "That fleet is not available."];
    }
    if ($fleet->hold_size <= 0) {
        confess [1009, 'That fleet has no cargo hold.'];
    }
    if ($fleet->body_id != $building->body_id) {
        confess [1013, "You can't manage a fleet that is not yours."];
    }
    if (not first {$fleet->type eq $_} (SHIP_TRADE_TYPES)) {
        confess [1009, 'You can only add transport ships to a supply chain.'];
    }
    my $quantity = $args->{quantity} || $fleet->quantity;

    my $max_berth = $building->body->max_berth;

    if ($fleet->berth_level > $max_berth) {
        confess [1009, "You don't have a high enough berth for this fleet."];
    }
    $fleet = $fleet->split($quantity);
    
    $building->add_fleet_to_supply_duty($fleet);
    return {
        status  =>$self->format_status($session, $building->body),
    };
}

sub add_fleet_to_waste_duty {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
            fleet_id        => shift,
        };
    }

    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});
    my $session      = $self->get_session($args);

    my $fleet_id    = $args->{fleet_id};

    if (not defined $building) {
        confess [1002, "Building not found."];
    }
    my $fleet = Lacune->db->resultset('Fleet')->find($fleet_id);
    if (not defined $fleet) {
        confess [1002, "Fleet not found."];
    }
    if ($fleet->task ne 'Docked') {
        confess [1009, "That fleet is not available."];
    }
    if ($fleet->hold_size <= 0) {
        confess [1009, 'That fleet has no cargo hold.'];
    }
    if ($fleet->body_id != $building->body_id) {
        confess [1013, "You can't manage a fleet that is not yours."];
    }
    if ($fleet->type !~ m/^scow/) {
        confess [1009, 'You can only add scows to a supply chain.'];
    }
    my $quantity = $args->{quantity} || $fleet->quantity;

    my $max_berth = $building->body->max_berth;

    if ($fleet->berth_level > $max_berth) {
        confess [1009, "You don't have a high enough berth for this fleet."];
    }
    $fleet = $fleet->split($quantity);
    $building->add_fleet_to_waste_duty($fleet);
    return {
        status  =>$self->format_status($session, $building->body),
    };
}

sub add_to_market {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
            offer           => shift,
            ask             => shift,
            fleet_id        => shift,
        };
    }

    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});
    if ($building->level < 1) {
        confess [1013, 'You cannot use a trade ministry that has not yet been built.'];
    }
    my $cache = Lacuna->cache;
    if (not $cache->add('trade_add_lock', $building->id, 1, 5)) {
        confess [1013, 'You have a trade setup in progress.  Please wait a few moments and try again.'];
    }
    my $guard = guard {
        $cache->delete('trade_add_lock',$building->id);
    };
    my $trade = $building->add_to_market($args->{offer}, $args->{ask}, $args->{fleet_id});
    return {
        trade_id    => $trade->id,
        status      => $self->format_status($empire, $building->body),
    };
}

sub create_supply_chain {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
            target_id       => shift,
            resource_type   => shift,
            resource_hour   => shift,
        };
    }

    my $session         = $self->get_session($args);
    my $empire          = $session->current_empire;
    my $building        = $session->current_building;
    my $body            = $building->body;
    my $max_chains      = $building->effective_level * 3;
    my $resource_hour   = $args->{resource_hour};
    my $resource_type   = $args->{resource_type};
    my $target_id       = $args->{target_id};
    my $building_id     = $args->{building_id};
    my $session_id      = $args->{session_id};

    if ($body->out_supply_chains->count >= $max_chains) {
        confess [1002, "You cannot create any more supply chains outgoing from this planet."];
    }

    unless (defined $resource_hour) {
        confess [1002, "You must specify an amount for resource_hour."];
    }
    if ($resource_hour < 0) {
        confess [1002, "Resource per Hour must be positive or zero."];
    }
    unless (first {$resource_type eq $_} (FOOD_TYPES, ORE_TYPES, qw(water waste energy))) {
        confess [1002, "That is not a valid resource_type."];
    }
    if ($body->id == $target_id) {
        confess [1002, "You can't set up a supply chain to yourself."];
    }
    my $target = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($target_id);
    unless ($target) {
        confess [1002, "Cannot find that target body."];
    }
    # Target must be own empire, or alliance SS
    if ($target->empire_id != $empire->id) {
        if ($target->class eq 'Lacuna::DB::Result::Map::Body::Planet::Station') {
            if ($target->alliance_id != $empire->alliance_id) {
                confess [1002, "You can only target one of your own alliances Space Stations."];
            }
        }
        else {
            confess [1002, "You must only target one of your own colonies."];
        }
    }

    my $chain       = $building->supply_chains->create({
        planet_id           => $body->id,
        building_id         => $building_id,
        target_id           => $target_id,
        resource_hour       => $resource_hour,
        resource_type       => $resource_type,
        percent_transferred => 0,
    });
    unless ($chain) {
        confess [1002, "Cannot create a supply chain."];
    }
    $building->recalc_supply_production;

    return $self->view_supply_chains($session_id, $building_id);
}


# Get fleets that are available to transport a trade
#
sub get_trade_fleets {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
            target_id       => shift,
        };
    }

    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});
    if (not defined $building) {
        confess [1002, "You must specify a building."];
    }
    if ($building->level < 1) {
        confess [1013, 'You cannot use a trade ministry that has not yet been built.'];
    }

    my $target = Lacuna->db->resultset('Map::Body')->find($args->{target_id}) if $args->{target_id};
    my @fleets;
    my $fleets = $building->trade_fleets;
    while (my $fleet = $fleets->next) {
        push @fleets, $fleet->get_status($target);
    }
    return {
        status      => $self->format_status($empire, $building->body),
        fleets      => \@fleets,
    };
}

sub get_waste_fleets {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
        };
    }

    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});
    if (not defined $building) {
        confess [1002, "You must specify a building."];
    }
    if ($building->level < 1) {
        confess [1013, 'You cannot use a trade ministry that has not yet been built.'];
    }

    # get the local star
    my $target      = Lacuna->db->resultset('Map::Star')->find($building->body->star_id);
    my @fleets;
    my $fleets      = $building->all_waste_ships;
    while (my $fleet = $fleets->next) {
        push @fleets, $fleet->get_status($target);
    }
    return {
        status      => $self->format_status($empire, $building->body),
        fleets      => \@fleets,
    };
}

sub get_supply_fleets {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
        };
    }

    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});
    if (not defined $building) {
        confess [1002, "You must specify a building."];
    }
    if ($building->level < 1) {
        confess [1013, 'You cannot use a trade ministry that has not yet been built.'];
    }

    my @fleets;
    my $fleets      = $building->all_supply_fleets;
    while (my $fleet = $fleets->next) {
        push @fleets, $fleet->get_status;
    }
    return {
        status      => $self->format_status($empire, $building->body),
        fleets      => \@fleets,
    };
}

sub view_supply_chains {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
        };
    }

    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});
    my $session      = $self->get_session($args);

    if (not defined $building) {
        confess [1002, "You must specify a building."];
    }
    if ($building->level < 1) {
        confess [1013, 'You cannot use a trade ministry that has not yet been built.'];
    }

    my $max_chains = $building->effective_level * 3;
    my @supply_chains;
    my $chains      = $building->supply_chains;
    while (my $chain = $chains->next) {
        push @supply_chains, $chain->get_status;
    }
    return {
        status          => $self->format_status($session, $building->body),
        supply_chains  => \@supply_chains,
        max_supply_chains => $max_chains,
    };
}

sub view_waste_chains {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
        };
    }

    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});
    my $session      = $self->get_session($args);

    if (not defined $building) {
        confess [1002, "You must specify a building."];
    }
    if ($building->level < 1) {
        confess [1013, 'You cannot use a trade ministry that has not yet been built.'];
    }

    my @waste_chains;
    my $chains      = $building->waste_chains;
    while (my $waste_push = $chains->next) {
        push @waste_chains, $waste_push->get_status;
    }
    return {
        status          => $self->format_status($session, $building->body),
        waste_chain     => \@waste_chains,
    };
}

sub delete_supply_chain {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
            supply_chain_id => shift,
        };
    }

    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});
    if (not defined $building) {
        confess [1002, "You must specify a building."];
    }
    if ($building->level < 1) {
        confess [1013, 'You cannot use a trade ministry that has not yet been built.'];
    }

    my $chain = Lacuna->db->resultset('SupplyChain')->find($args->{supply_chain_id});
    if ($chain) {
        $building->remove_supply_chain($chain);
    }
    return $self->view_supply_chains($args->{session_id}, $args->{building_id});
}

sub update_supply_chain {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
            supply_chain_id => shift,
            resource_type   => shift,
            resource_hour   => shift,
        };
    }

    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});
    my $supply_chain_id = $args->{supply_chain_id};
    my $chain       = $building->supply_chains->find($supply_chain_id);
    unless ($chain) {
        confess [1002, "That Supply Chain does not exist on this planet."];
    }
    my $resource_type   = defined $args->{resource_type} ? $args->{resource_type} : $chain->resource_type;
    my $resource_hour   = defined $args->{resource_hour} ? $args->{resource_hour} : $chain->resource_hour;

    if (not defined $building) {
        confess [1002, "You must specify a building."];
    }
    if ($building->level < 1) {
        confess [1013, 'You cannot use a trade ministry that has not yet been built.'];
    }
    unless ($supply_chain_id) {
        confess [1002, "You must specify a supply chain id."];
    }
    unless ($resource_hour >= 0) {
        confess [1002, "Resource per Hour must be positive or zero."];
    }
    unless (first {$resource_type eq $_} (FOOD_TYPES, ORE_TYPES, qw(water waste energy))) {
        confess [1002, "That is not a valid resource_type."];
    }
    $chain->resource_hour(int($resource_hour));
    $chain->resource_type($resource_type);
    $chain->update;
    $building->recalc_supply_production;

    return $self->view_supply_chains($args->{session_id}, $args->{building_id});
}

sub update_waste_chain {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
            waste_chain_id  => shift,
            waste_hour      => shift,
        };
    }

    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});
    if (not defined $building) {
        confess [1002, "You must specify a building."];
    }
    if ($building->level < 1) {
        confess [1013, 'You cannot use a trade ministry that has not yet been built.'];
    }

    my $waste_chain_id = $args->{waste_chain_id};
    my $waste_hour  = $args->{waste_hour};

    my $chain       = $building->waste_chains->find($waste_chain_id);
    unless ($chain) {
        confess [1002, "That Waste Chain does not exist on this planet."];
    }

    unless (defined $waste_hour) {
        confess [1002, "You must specify an amount for waste_hour."];
    }
    unless ($waste_hour >= 0) {
        confess [1002, "Waste per Hour must be positive or zero."];
    }

    $chain->waste_hour(int($waste_hour));
    $chain->update;
    $building->recalc_waste_production;

    return $self->view_waste_chains($args->{session_id}, $args->{building_id});
}

sub remove_supply_fleet {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
            fleet_id        => shift,
            quantity        => shift,
        };
    }

    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});
    if (not defined $building) {
        confess [1002, "You must specify a building."];
    }
    if ($building->level < 1) {
        confess [1013, 'You cannot use a trade ministry that has not yet been built.'];
    }

    my $fleet       = Lacuna->db->resultset('Fleet')->find($args->{fleet_id});
    unless (defined $fleet) {
        confess [1002, "Fleet not found."];
    }
    my $quantity    = defined $args->{quantity} ? $args->{quantity} : $fleet->quantity;

    unless ($fleet->task eq 'Supply Chain') {
        confess [1009, "That fleet is not in a Supply Chain."];
    }
    unless ($fleet->body_id eq $building->body_id) {
        confess [1013, "You can't manage a fleet that is not yours."];
    }

    my $supply_chain = $building->supply_chains->search({},{rows => 1})->single;

    $fleet = $fleet->split($quantity);

    if (defined $supply_chain) {
        my $from = $supply_chain->target;
        $building->send_supply_fleet_home($from, $fleet);
    }
    else {
        $fleet->land->update;
    }
    return $self->view_supply_chains($args->{session_id}, $args->{building_id});
}

sub remove_waste_fleet {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
            fleet_id        => shift,
            quantity        => shift,
        };
    }

    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});
    if (not defined $building) {
        confess [1002, "You must specify a building."];
    }
    if ($building->level < 1) {
        confess [1013, 'You cannot use a trade ministry that has not yet been built.'];
    }

    my $fleet       = Lacuna->db->resultset('Fleet')->find($args->{fleet_id});
    unless (defined $fleet) {
        confess [1002, "Fleet not found."];
    }
    my $quantity    = defined $args->{quantity} ? $args->{quantity} : $fleet->quantity;

    unless ($fleet->task eq 'Waste Chain') {
        confess [1009, "That fleet is not in a Waste Chain."];
    }
    unless ($fleet->body_id eq $building->body_id) {
        confess [1013, "You can't manage a fleet that is not yours."];
    }

    $fleet = $fleet->split($quantity);

    my $waste_chain = $building->waste_chains->search({},{rows => 1})->single;

    if (defined $waste_chain) {
        my $from = $building->body->star;
        $building->send_waste_fleet_home($from, $fleet);
    }
    else {
        $fleet->land->update;
    }
    return $self->view_waste_chains($args->{session_id}, $args->{building_id});
}


#------------------------------------------------------------------------------
#
#
#
#


sub push_items {
    my ($self, $args) = @_;

    if (ref($args) ne "HASH") {
        confess [1000,"Must call push_items with a hash ref"];
    }

    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});
    my $building_id = $building->id;
    my $items       = $args->{items};

    if (not defined $building) {
        confess [1002, "You must specify a building."];
    }
    if ($building->level < 1) {
        confess [1013, 'You cannot use a trade ministry that has not yet been built.'];
    }

    # Target
    my $target = $self->find_target($args->{target});

    my $cache = Lacuna->cache;
    if (! $cache->add('trade_add_lock', $building_id, 1, 5)) {
        confess [1013, 'You have a trade setup in progress.  Please wait a few moments and try again.'];
    }
    my $guard = guard {
        $cache->delete('trade_add_lock',$building_id);
    };

    if ($target->class eq 'Lacuna::DB::Result::Map::Body::Planet::Station') {
        my $planet = $building->body;
        if ($target->alliance_id == $empire->alliance_id) {
            # You can push anything to your Alliance's Space Stations
        }
        elsif ($target->in_jurisdiction($planet)) {
            # Allowed to push food, ore, water and energy only to SS that control your star
            foreach my $item (@{$items}) {
                given($item->{type}) {
                    when([qw(waste glyph plan prisoner ship)]) {
                        confess [1010, "You cannot push $item->{type} to that space station."];
                    }
                }
            }
        }
        else {
            confess [1010, 'You cannot push items to that space station.'];
        }
    }
    else {
        # You can push anything to your own planets
        unless ($target->empire_id == $empire->id) {
            confess [1010, 'You cannot push items to a planet that is not your own.'];
        }
    }

    my $fleet = $building->push_items($target, $items, $args->{fleet});

    return {
        status      => $self->format_status($empire, $building->body),
        fleet       => $fleet->get_status,
    };
}

sub withdraw_from_market {
    my ($self, $session_id, $building_id, $trade_id) = @_;
    unless ($trade_id) {
        confess [1002, 'You have not specified a trade to withdraw.'];
    }
    my $cache = Lacuna->cache;
    if (! $cache->add('trade_lock', $trade_id, 1, 5)) {
        confess [1013, 'A buyer has placed an offer on this trade. Please wait a few moments and try again.'];
    }
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $trade = $building->my_market->find($trade_id);
    unless (defined $trade) {
        confess [1002, 'Could not find that trade. Perhaps it has already been accepted.'];
    }
    $trade->withdraw($building->body);
    return {
        status      => $self->format_status($session, $building->body),
    };
}

__PACKAGE__->register_rpc_method_names(qw(
    get_supply_fleetss 
    view_supply_chains 
    add_supply_fleet 
    remove_supply_fleet 
    create_supply_chain 
    delete_supply_chain 
    update_supply_chain 
    get_waste_fleets 
    view_waste_chains 
    add_waste_fleet 
    remove_waste_fleet 
    update_waste_chain 
    report_abuse 
    view_my_market 
    view_market 
    accept_from_market 
    withdraw_from_market 
    add_to_market 
    push_items 
    get_trade_fleets 
    get_stored_resources 
    get_fleets 
    get_fleet_summary
    get_prisoners 
    get_plan_summary 
    get_glyph_summary
));

no Moose;
__PACKAGE__->meta->make_immutable;

