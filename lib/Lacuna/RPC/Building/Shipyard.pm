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
    my ($self, %args) = @_;

    my $session     = $self->get_session(\%args);
    my $empire      = $session->current_empire;
    my $building    = $session->current_building;
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
    my $page_number = $args{page_number} || 1;
    if (not $args{no_paging}) {
        $fleets = $fleets->search({}, {rows => $args{items_per_page}, page => $page_number} );
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
        status                      => $args{no_status} ? {} : $self->format_status($empire, $body),
        number_of_fleets_building   => $sum->get_column('number_of_fleets'),
        number_of_ships_building    => $sum->get_column('number_of_ships'),
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
    my $session  = $self->get_session($args);
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $body     = $building->body;
    
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
}

sub delete_build {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
            ship_id         => shift,
        };
    }
    my $session  = $self->get_session($args);
    my $empire   = $session->current_empire;
    my $building = $session->current_building;

    my $ship_id = $args->{ship_id};

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


sub subsidize_fleet {
    my ($self, $args) = @_;

    if (ref($args) ne "HASH") {
        confess [1000, "You have not supplied a hash reference"];
    }
    my $session  = $self->get_session($args);
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    unless ($building->effective_level > 0 and $building->efficiency == 100) {
        confess [1003, "You must have a functional Space Port!"];
    }
    my $fleet = Lacuna->db->resultset('Fleet')->search({
        id          => $args->{fleet_id},
        shipyard_id => $building->id,
        task        => 'Building',
    })->single;

    if (not $fleet) {
        confess [1003, "Cannot find that fleet!"];
    }

    my $cost = $fleet->quantity;
    unless ($empire->essentia >= $cost) {
        confess [1011, "Not enough essentia."];
    }

    $fleet->reschedule_queue;
    $fleet->finish_construction;

    $empire->spend_essentia({
        amount  => $cost,
        reason  => 'fleet build subsidy after the fact',
    });
    $empire->update;

    return $self->view({session => $empire, building => $building, no_status => $args->{no_status}});
}


# Required
#   session_id
#   type        - 'snark','sweeper', etc
#   body_id OR building_id
#   building_id should be an array of shipyards
#   autoselect
#       this            - only use shipyards specified in the building_id array
#       these           - only use shipyards specified in the building_id array
#       all             - use all shipyards on the body
#       equal_or_higher - use all shipyards equal to or higher than the first building
#       equal           - use all shipyards equal to the first building
#
sub build_fleet {
    my ($self, %args) = @_;

    my $session     = $self->get_session(\%args);
    my $empire      = $session->current_empire;

    my $building_ids    = $args{building_ids};
    my $type            = $args{type};
    my $quantity        = $args{quantity} || 1;
    my $autoselect      = lc $args{autoselect};

    if ($quantity <= 0 or int($quantity) != $quantity) {
        confess [1001, "Quantity must be a positive integer"];
    }

    if (ref($building_ids) ne 'ARRAY') {
        confess [1001, "building_ids must be an array"];
    }
    if (scalar(@$building_ids) < 1) {
        confess [1001, "you must specify at least one building_id"];
    }


    my @buildings;
    push @buildings, map { $self->get_building($session, $_) } @$building_ids;
    
    # All buildings must be on the same body
    foreach my $building (@buildings) {
        if ($building->body_id != $buildings[0]->body_id) {
            confess [1001, "All buildings must be on the same planet"];
        }
    }
    my $body = $self->get_body($session, $buildings[0]->body_id);

    my @all_shipyards = grep {
        $_->class eq 'Lacuna::DB::Result::Building::Shipyard' &&
        $_->level > 0 &&
        $_->efficiency >= 100
    } @{$body->building_cache};

    if ($autoselect eq 'this' or $autoselect eq 'these') {
        # just use the shipyards specified
    }
    elsif ($autoselect eq 'all') {
        @buildings = @all_shipyards;
    }
    elsif ($autoselect eq 'equal_or_higher') {
        confess [1011, 'Too many building_ids'] if @buildings > 1;
        @buildings = grep {
            $_->level >= $buildings[0]->level
        } @all_shipyards;
    }
    elsif ($autoselect eq 'equal') {
        confess [1011, 'Too many building_ids'] if @buildings > 1;
        @buildings = grep {
            $_->level == $buildings[0]->level
        } @all_shipyards;
    }
    else {
        confess [1011, "Unknown autoselect option: $autoselect"];
    }

    # TODO Split the fleet between different shipyards
    # but for now just build at the current one...

    my $building = $buildings[0];

    my $fleet = Lacuna->db->resultset('Fleet')->new({
        type        => $type, 
        quantity    => $quantity,
    });
    my $costs = $building->get_fleet_costs($fleet);
    $building->can_build_fleet($fleet, $costs);
    $building->spend_resources_to_build_fleet($costs);
    $building->build_fleet($fleet, $costs->{seconds});
    $fleet->body_id($body->id);
    $fleet->insert;

    return $self->view_build_queue({ 
        no_status   => $args{no_status}, 
        session_id  => $empire, 
        building_id => $building },
    );
}


sub repair_fleet {
    my ($self, $args) = @_;

    my $session  = $self->get_session($args);
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $body     = $building->body;

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
    my $self = shift;
    my $args = shift;
        
    if (ref($args) ne "HASH") {
        $args = {
            session_id  => $args,
            building_id => shift,
            tag         => shift,
        };
    }

    my $session  = $self->get_session($args);
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $body     = $building->body;

    my %repairable;
    my $fleet_rs = Lacuna->db->resultset('Fleet')->search({
        body_id     => $body->id,
        task        => 'Docked',
    });
    # Find all fleets with fractional quantity
    my $fleets;
    FLEET:
    while (my $fleet = $fleet_rs->next) {
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
    my $session  = $self->get_session($args);
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $body     = $building->body;

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

