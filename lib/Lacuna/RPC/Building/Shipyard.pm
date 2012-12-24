package Lacuna::RPC::Building::Shipyard;

use 5.010;
use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';
use Lacuna::Constants qw(SHIP_TYPES);
use Data::Dumper;

sub app_url {
    return '/shipyard';
}


sub model_class {
    return 'Lacuna::DB::Result::Building::Shipyard';
}


sub view_build_queue {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
            page_number     => shift,
            items_per_page  => 25,
            no_paging       => 0,            
        };
    }

    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});
    my $body        = $building->body;

    my @constructing;
    my $fleets = $building->fleets_under_construction;

    my ($sum) = $fleets->search(undef, {
        "+select" => [
            { count => 'id' },
            { sum   => 'quantity' },
        ],
        "+as" => [qw(number_of_fleets number_of_ships)],
    });
    $fleets = $fleets->search({},{ order_by => 'date_available'});
    my $page_number = $args->{page_number} || 1;
    if (not $args->{no_paging}) {
        $fleets = $fleets->search({}, {rows => $args->{items_per_page}, page => $page_number} );
    }

    while (my $fleet = $fleets->next) {
        push @constructing, {
            id              => $fleet->id,
            type            => $fleet->type,
            type_human      => $fleet->type_formatted,
            date_completed  => $fleet->date_available_formatted,
            quantity        => $fleet->quantity,
        }
    }

    return {
        status                      => $args->{no_status} ? {} : $self->format_status($empire, $body),
        number_of_fleets_building   => $sum->get_column('number_of_fleets'),
        fleets_building             => \@constructing,
        cost_to_subsidize           => $sum->get_column('number_of_ships') || 0,
        building                    => {
            work        => {
                seconds_remaining   => $building->work_seconds_remaining,
                start               => $building->work_started_formatted,
                end                 => $building->work_ends_formatted,
            },
        },
    };
}


sub subsidize_build_queue {
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
    my $body        = $building->body;
    my $fleets      = $building->fleets_under_construction;
    my $ships       = 0;
    while (my $fleet = $fleets->next) {
        $ships += $fleet->quantity;
    }
    my $cost        = $ships;

    unless ($empire->essentia >= $cost) {
        confess [1011, "Not enough essentia."];
    }

    $empire->spend_essentia({
        amount      => $cost, 
        reason      => 'ship build subsidy after the fact',
    });    
    $empire->update;

    $fleets->reset;
    while (my $fleet = $fleets->next) {
        $fleet->finish_construction;
    }
    $building->finish_work->update;
 
    return $self->view_build_queue({
        session_id  => $empire, 
        building_id => $building, 
        no_status   => $args->{no_status},
    });

sub delete_build {
    my ($self, $session_id, $building_id, $ship_id) = @_;

    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;

    if (!ref $ship_id)
    {
        $ship_id = [ $ship_id ];
    }
    elsif (ref $ship_id eq 'ARRAY' )
    {
        confess [1000, 'Invalid ship ID.' ]
            unless none { ref $_ } @$ship_id;
    }
    else
    {
        confess [1000, 'Invalid ship ID reference.' ];
    }

    my $ships = Lacuna->db->resultset('Ships')->search({
            id => $ship_id,
            task => 'Building',
    });
    my $cancelled_count = 0;
    while (my $ship = $ships->next)
    {
        $ship->cancel_build;
        ++$cancelled_count;
    }

    return {
        status          => $self->format_status($session, $building->body),
        cancelled_count => $cancelled_count,
    };
}


sub subsidize_ship {
    my ($self, $args) = @_;

    if (ref($args) ne "HASH") {
        confess [1000, "You have not supplied a hash reference"];
    }
    my $session  = $self->get_session({session_id => $args->{session_id}, building_id => $args->{building_id} });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    unless ($building->effective_level > 0 and $building->efficiency == 100) {
        confess [1003, "You must have a functional Space Port!"];
    }
    my $scheduled_ship = Lacuna->db->resultset('Ships')->find({id => $args->{ship_id}});

    if (not $scheduled_ship) {
        confess [1003, "Cannot find that ship!"];
    }
    if ($scheduled_ship->shipyard_id != $building->id or $scheduled_ship->task ne 'Building') {
        confess [1003, "That ship is not in construction at this shipyard!"];
    }

    my $cost = 1;
    unless ($empire->essentia >= $cost) {
        confess [1011, "Not enough essentia."];
    }
    $empire->spend_essentia({
        amount  => $cost,
        reason  => 'ship build subsidy after the fact',
    });
    $empire->update;

    $scheduled_ship->reschedule_queue;
    $scheduled_ship->finish_construction;

    return $self->view({session => $empire, building => $building, no_status => $args->{no_status}});
}


sub build_fleet {
    my $self = shift;
    my $args = shift;
        
    if (ref($args) ne "HASH") {
        $args = {
            session_id  => $args,
            building_id => shift,
            type        => shift,
            quantity    => shift,
        };
    }
    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});
    my $body        = $building->body;

    my $quantity    = defined $args->{quantity} ? $args->{quantity} : 1;
    if ($quantity <= 0 or int($quantity) != $quantity) {
        confess [1001, "Quantity must be a positive integer"];
    }
    my $body_id     = $building->body_id;

    my $fleet = Lacuna->db->resultset('Fleet')->new({
        type        => $args->{type}, 
        quantity    => $args->{quantity},
    });
    my $costs = $building->get_fleet_costs($fleet);
    $building->can_build_fleet($fleet, $costs);
    $building->spend_resources_to_build_fleet($costs);
    $building->build_fleet($fleet, $costs->{seconds});
    $fleet->body_id($body_id);
    $fleet->insert;

    return $self->view_build_queue({ 
        no_status   => $args->{no_status}, 
        session_id  => $empire, 
        building_id => $building },
    );
}


sub repair_fleet {
    my ($self, $args) = @_;

    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});
    my $body        = $building->body;
    my $fleet       = Lacuna->db->resultset('Fleet')->find($args->{fleet_id});

    if (not $fleet) {
        confess [1010, "Fleet cannot be found"];
    }
    my $quantity    = $fleet->quantity;
    if ($quantity == int($quantity)) {
        confess [1010, "That fleet has no damaged ships"];
    }
    my $costs = $building->get_fleet_repair_costs($fleet);
    $building->can_repair_fleet($fleet, $costs);
    $building->spend_resources_to_repair_fleet($costs);
    $building->repair_fleet($fleet, $costs->{seconds});



}


sub get_repairable {
    my ($self, $args) = @_;

    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});
    my $body        = $building->body;

    my %repairable;
    my $fleet_rs = Lacuna->db->resultset('Fleet')->search({
        body_id     => $body->id,
        task        => 'Docked',
    });
    # Find all fleets with fractional quantity
    my $fleets;
    FLEET:
    foreach my $fleet ($fleet_rs->next) {
        next FLEET if $fleet->quantity == int($fleet->quantity);
        my $item = {
            attributes => {
                speed           => $fleet->speed,
                stealth         => $fleet->stealth,
                hold_size       => $fleet->hold_size,
                berth_level     => $fleet->base_berth_level,
                combat          => $fleet->combat,
                max_occupants   => $fleet->max_occupants,
            },
            id              => $fleet->id,
            type            => $fleet->type,
            type_human      => $fleet->type_human,
            cost            => $building->get_fleet_repair_costs($fleet),
        };
        push @$fleets, $item;
    }
    my $docks = 0;
    my $port = $body->spaceport;
    if (defined $port) {
        $docks = $port->docks_available;
    }
    my $max_ships = $building->max_ships;
    my $total_ships_building = Lacuna->db->resultset('Fleet')->search({
        body_id => $building->body_id, 
        task    => ['Building','Repairing'],
    })->count;

    return {
        repairable      => $fleets,
        docks_available => $docks,
        status          => $args->{no_status} ? {} : $self->format_status($empire, $body),
        build_queue_max => $max_ships,
        build_queue_used => $total_ships_building,
     };
}

sub get_buildable {
    my $self = shift;
    my $args = shift;
        
    if (ref($args) ne "HASH") {
        $args = {
            session_id  => $args,
            building_id => shift,
            tag         => shift,
        };
    }
    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});
    my $body        = $building->body;

    my %buildable;
    foreach my $type (SHIP_TYPES) {
        my $fleet = Lacuna->db->resultset('Fleet')->new({ type => $type, quantity => 1 });
        my @tags = @{$fleet->build_tags};
        if ($args->{tag}) {
            next unless ($args->{tag} ~~ \@tags);
        }
        my $can = eval{$building->can_build_fleet($fleet)};
        my $reason = $@;
        $buildable{$type} = {
            attributes  => {
                speed           => $building->set_fleet_speed($fleet),
                stealth         => $building->set_fleet_stealth($fleet),
                hold_size       => $building->set_fleet_hold_size($fleet),
                berth_level     => $fleet->base_berth_level,
                combat          => $building->set_fleet_combat($fleet),
                max_occupants   => $fleet->max_occupants
            },
            tags        => \@tags,
            cost        => $building->get_fleet_costs($fleet),
            can         => ($can) ? 1 : 0,
            reason      => $reason,
            type_human  => $fleet->type_formatted,
        };
    }
    my $docks = 0;
    my $port = $body->spaceport;
    if (defined $port) {
        $docks = $port->docks_available;
    }
    my $max_ships = $building->max_ships;
    my $total_ships_building = Lacuna->db->resultset('Fleet')->search({
        body_id => $building->body_id, 
        task    => ['Building','Repairing'],
    })->count;

    return {
        buildable       => \%buildable,
        docks_available => $docks,
        build_queue_max => $max_ships,
        build_queue_used => $total_ships_building,
        status          => $args->{no_status} ? {} : $self->format_status($empire, $body),
    };
}


__PACKAGE__->register_rpc_method_names(qw(
    get_buildable 
    get_repairable
    build_fleet 
    repair_fleet
    view_build_queue 
    subsidize_build_queue
    subsidize_fleet
));

no Moose;
__PACKAGE__->meta->make_immutable;

