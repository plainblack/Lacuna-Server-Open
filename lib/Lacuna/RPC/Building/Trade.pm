package Lacuna::RPC::Building::Trade;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

with 'Lacuna::Role::TraderRpc';

sub app_url {
    return '/trade';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Trade';
}

sub get_trade_ships {
    my ($self, $session_id, $building_id, $target_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $target = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($target_id) if $target_id;
    my @ships;
    my $ships = $building->trade_ships;
    while (my $ship = $ships->next) {
        push @ships, $ship->get_status($target);
    }
    return {
        status      => $self->format_status($empire, $building->body),
        ships       => \@ships,
    };
}

sub push_items {
    my ($self, $session_id, $building_id, $target_id, $items, $options) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    unless ($target_id) {
        confess [1002, "You must specify a target body id."];
    }
    my $target = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($target_id);
    unless (defined $target) {
        confess [1002, 'The target body you specified could not be found.'];
    }
    unless ($target->empire_id eq $empire->id) {
        confess [1010, 'You cannot push items to a planet that is not your own.'];
    }
    my $ship = $building->push_items($target, $items, $options);
    return {
        status      => $self->format_status($empire, $building->body),
        ship        => $ship->get_status,
    };
}

sub add_trade { # deprecated
    my ($self, $session_id, $building_id, $offer, $ask, $options) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $trade = $building->add_trade($offer, $ask, $options);
    return {
        trade_id    => $trade->id,
        status      => $self->format_status($empire, $building->body),
    };
}

sub withdraw_trade {
    my ($self, $session_id, $building_id, $trade_id) = @_;
    unless ($trade_id) {
        confess [1002, 'You have not specified a trade to withdraw.'];
    }
    my $cache = Lacuna->cache;
    if ($cache->get('trade_lock', $trade_id)) {
        confess [1013, 'A buyer has placed an offer on this trade. Please wait a few moments and try again.'];
    }
    $cache->set('trade_lock',$trade_id,1,5);
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $trade = $building->trades->find($trade_id);
    unless (defined $trade) {
        confess [1002, 'Could not find that trade. Perhaps it has already been accepted.'];
    }
    $trade->withdraw($building->body);
    return {
        status      => $self->format_status($empire, $building->body),
    };
}

sub withdraw_from_market {
    my ($self, $session_id, $building_id, $trade_id) = @_;
    unless ($trade_id) {
        confess [1002, 'You have not specified a trade to withdraw.'];
    }
    my $cache = Lacuna->cache;
    if ($cache->get('trade_lock', $trade_id)) {
        confess [1013, 'A buyer has placed an offer on this trade. Please wait a few moments and try again.'];
    }
    $cache->set('trade_lock',$trade_id,1,5);
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $trade = $building->market->find($trade_id);
    unless (defined $trade) {
        confess [1002, 'Could not find that trade. Perhaps it has already been accepted.'];
    }
    $trade->withdraw($building->body);
    return {
        status      => $self->format_status($empire, $building->body),
    };
}

sub accept_trade { # deprecated
    my ($self, $session_id, $building_id, $trade_id, $guid, $solution, $options) = @_;
    unless ($trade_id) {
        confess [1002, 'You have not specified a trade to accept.'];
    }
    my $cache = Lacuna->cache;
    if ($cache->get('trade_lock', $trade_id)) {
        confess [1013, 'Another buyer has placed an offer on this trade. Please wait a few moments and try again.'];
    }
    $cache->set('trade_lock',$trade_id,1,5);
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $building->validate_captcha($empire, $guid, $solution, $trade_id);
    my $ship = $building->next_available_trade_ship($options->{ship_id});
    unless (defined $ship) {
        $cache->delete('trade_lock',$trade_id);
        confess [1011, 'You do not have a ship available to transport cargo.'];
    }
    my $trade = $building->trades->find($trade_id);
    unless (defined $trade) {
        $cache->delete('trade_lock',$trade_id);
        confess [1002, 'Could not find that trade. Perhaps it has already been accepted.'];
    }
    unless ($ship->hold_size >= $trade->ask_quantity) {
        $cache->delete('trade_lock',$trade_id);
        confess [1011, 'You need a cargo ship with a hold size of at least '.$trade->ask_quantity.'.'];
    }
    my $offer_ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($trade->ship_id);
    unless (defined $offer_ship) {
        $trade->withdraw;
        confess [1009, 'Trade no longer available.'];
    }

    my $body = $building->body;
    if ($trade->ask_type eq 'essentia') {
        unless ($empire->essentia >= $trade->ask_quantity) {
            $cache->delete('trade_lock',$trade_id);
            confess [1011, 'You need at least '.$trade->ask_quantity.' essentia to make this trade.']
        }
        $empire->spend_essentia($trade->ask_quantity, 'Trade Price')->update;
        $ship->send(
            target  => $trade->body,
            payload => { essentia => $trade->ask_quantity },
        );
    }
    else {
        unless ($body->type_stored($trade->ask_type) >= $trade->ask_quantity) {
            $cache->delete('trade_lock',$trade_id);
            confess [1011, 'You need at least '.$trade->ask_quantity.' '.$trade->ask_type.' to make this trade.'];
        }
        $body->spend_type($trade->ask_type, $trade->ask_quantity);
        $body->update;
        $ship->send(
            target  => $trade->body,
            payload => { resources => { $trade->ask_type => $trade->ask_quantity }}
        )
    }
    my $cargo_log = Lacuna->db->resultset('Lacuna::DB::Result::Log::Cargo');
    $cargo_log->new({
        message     => 'trade ministry offer accepted',
        body_id     => $trade->body_id,
        data        => $trade->payload,
        object_type => ref($trade),
        object_id   => $trade->id,
    })->insert;
    $cargo_log->new({
        message     => 'trade ministry ask accepted',
        body_id     => $trade->body_id,
        data        => {$trade->ask_type => $trade->ask_quantity},
        object_type => ref($trade),
        object_id   => $trade->id,
    })->insert;
    $cargo_log->new({
        message     => 'send ask',
        body_id     => $ship->foreign_body_id,
        data        => $ship->payload,
        object_type => ref($ship),
        object_id   => $ship->id,
    })->insert;
    
    $offer_ship->send(
        target  => $body,
        payload => $trade->payload,
    );
    $cargo_log->new({
        message     => 'send offer',
        body_id     => $offer_ship->foreign_body_id,
        data        => $offer_ship->payload,
        object_type => ref($offer_ship),
        object_id   => $offer_ship->id,
    })->insert;
    
    $trade->body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'trade_accepted.txt',
        params      => [$trade->offer_description, $trade->ask_description],
    );
    $trade->delete;

    return {
        status      => $self->format_status($empire, $building->body),
    };
}


sub accept_from_market {
    my ($self, $session_id, $building_id, $trade_id, $guid, $solution) = @_;
    unless ($trade_id) {
        confess [1002, 'You have not specified a trade to accept.'];
    }
    my $cache = Lacuna->cache;
    if ($cache->get('trade_lock', $trade_id)) {
        confess [1013, 'Another buyer has placed an offer on this trade. Please wait a few moments and try again.'];
    }
    $cache->set('trade_lock',$trade_id,1,5);
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $building->validate_captcha($empire, $guid, $solution, $trade_id);
    my $trade = $building->trades->find($trade_id);
    unless (defined $trade) {
        $cache->delete('trade_lock',$trade_id);
        confess [1002, 'Could not find that trade. Perhaps it has already been accepted.'];
    }
    my $offer_ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($trade->ship_id);
    unless (defined $offer_ship) {
        $trade->withdraw;
        confess [1009, 'Trade no longer available.'];
    }

    my $body = $building->body;
    unless ($empire->essentia >= $trade->ask) {
        $cache->delete('trade_lock',$trade_id);
        confess [1011, 'You need at least '.$trade->ask.' essentia to make this trade.']
    }
    $empire->spend_essentia($trade->ask, 'Trade Price')->update;
    $trade->body->empire->add_essentia($trade->ask, 'Trade Income')->update;
    my $cargo_log = Lacuna->db->resultset('Lacuna::DB::Result::Log::Cargo');
    $cargo_log->new({
        message     => 'trade ministry offer accepted',
        body_id     => $trade->body_id,
        data        => $trade->payload,
        object_type => ref($trade),
        object_id   => $trade->id,
    })->insert;
    $offer_ship->send(
        target  => $body,
        payload => $trade->payload,
    );
    $cargo_log->new({
        message     => 'send offer',
        body_id     => $offer_ship->foreign_body_id,
        data        => $offer_ship->payload,
        object_type => ref($offer_ship),
        object_id   => $offer_ship->id,
    })->insert;
    
    $trade->body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'trade_accepted.txt',
        params      => [join("\n",@{$trade->format_description_of_payload($trade->payload)}), $trade->ask.' essentia'],
    );
    $trade->delete;

    return {
        status      => $self->format_status($empire, $building->body),
    };
}

sub add_to_market {
    my ($self, $session_id, $building_id, $offer, $ask, $options) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $trade = $building->add_to_market($offer, $ask, $options);
    return {
        trade_id    => $trade->id,
        status      => $self->format_status($empire, $building->body),
    };
}



__PACKAGE__->register_rpc_method_names(qw(view_my_market view_market accept_from_market withdraw_from_market add_to_market push_items get_trade_ships get_stored_resources add_trade withdraw_trade accept_trade view_my_trades view_available_trades get_ships get_prisoners get_plans get_glyphs));


no Moose;
__PACKAGE__->meta->make_immutable;

