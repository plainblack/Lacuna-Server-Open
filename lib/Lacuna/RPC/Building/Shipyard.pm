package Lacuna::RPC::Building::Shipyard;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';
use Lacuna::Constants qw(SHIP_TYPES);
use List::Util qw(none);

sub app_url {
    return '/shipyard';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Shipyard';
}

sub view_build_queue {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $body = $building->body;
    $page_number ||= 1;
    my @building;
    my $ships = Lacuna->db->resultset('Ships')->search(
        { shipyard_id => $building->id, task => 'Building' },
        { order_by    => 'date_available', rows => 25, page => $page_number },
        );
    while (my $ship = $ships->next) {
        push @building, {
            id              => $ship->id,
            type            => $ship->type,
            type_human      => $ship->type_formatted,
            date_completed  => $ship->date_available_formatted,
        }
    }
    my $number_of_ships = $ships->pager->total_entries;
    return {
        status                      => $self->format_status($empire, $body),
        number_of_ships_building    => $number_of_ships,
        ships_building              => \@building,
        cost_to_subsidize           => $number_of_ships,
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
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $body = $building->body;

    my $ships = $building->building_ships;

    my $cost = $ships->count;
    unless ($empire->essentia >= $cost) {
        confess [1011, "Not enough essentia."];    
    }

    $empire->spend_essentia({
        amount      => $cost, 
        reason      => 'ship build subsidy after the fact',
    });    
    $empire->update;

    while (my $ship = $ships->next) {
        $ship->finish_construction;
    }
    $building->finish_work->update;
 
    return $self->view($empire, $building);
}

sub delete_build {
    my ($self, $session_id, $building_id, $ship_id) = @_;

    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);

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
        status          => $self->format_status($empire, $building->body),
        cancelled_count => $cancelled_count,
    };
}


sub subsidize_ship {
    my ($self, $args) = @_;

    if (ref($args) ne "HASH") {
        confess [1000, "You have not supplied a hash reference"];
    }
    my $empire              = $self->get_empire_by_session($args->{session_id});
    my $building            = $self->get_building($empire, $args->{building_id});
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

    return $self->view_build_queue($empire, $building);

}


sub build_ship {
    my ($self, $session_id, $building_id, $type, $quantity) = @_;
    $quantity = defined $quantity ? $quantity : 1;
    if ($quantity > 600) { # of course, this would only be reached if the planet had 20 shipyards at level 30
        confess [1011, "You can only build up to 600 ships at a time"];
    }
    if ($quantity <= 0 or int($quantity) != $quantity) {
        confess [1001, "Quantity must be a positive integer"];
    }
    my $costs;
    my $empire      = $self->get_empire_by_session($session_id);
    my $building    = $self->get_building($empire, $building_id);
    my $body_id     = $building->body_id;

    for (1..$quantity) {
        my $ship = Lacuna->db->resultset('Ships')->new({type => $type});
        if (not defined $costs) {
            $costs = $building->get_ship_costs($ship);
            $building->can_build_ship($ship, $costs, $quantity);
        }
        $building->spend_resources_to_build_ship($costs);
        $building->build_ship($ship, $costs->{seconds});
        $ship->body_id($body_id);
        $ship->update;
    }
    return $self->view_build_queue($empire, $building);
}


sub get_buildable {
    my ($self, $session_id, $building_id, $tag) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my %buildable;
    foreach my $type (SHIP_TYPES) {
        my $ship = Lacuna->db->resultset('Ships')->new({type=>$type});
        my @tags = @{$ship->build_tags};
        if ($tag) {
            next unless ($tag ~~ \@tags);
        }
        my $can = eval{$building->can_build_ship($ship)};
        my $reason = $@;
        $buildable{$type} = {
            attributes  => {
                speed           => $building->set_ship_speed($ship),
                stealth         => $building->set_ship_stealth($ship),
                hold_size       => $building->set_ship_hold_size($ship),
                berth_level     => $ship->base_berth_level,
                combat          => $building->set_ship_combat($ship),
                max_occupants   => $ship->max_occupants
            },
            tags        => \@tags,
            cost        => $building->get_ship_costs($ship),
            can         => ($can) ? 1 : 0,
            reason      => $reason,
            type_human  => $ship->type_formatted,
        };
    }
    my $docks = 0;
    my $port = $building->body->spaceport;
    if (defined $port) {
        $docks = $port->docks_available;
    }
    my $max_ships = $building->max_ships;
    my $total_ships_building = Lacuna->db->resultset('Ships')->search({body_id => $building->body_id, task=>'Building'})->count;

    return {
        buildable       => \%buildable,
        docks_available => $docks,
        build_queue_max => $max_ships,
        build_queue_used => $total_ships_building,
        status          => $self->format_status($empire, $building->body),
        };
}


__PACKAGE__->register_rpc_method_names(qw(
    get_buildable 
    build_ship 
    view_build_queue 
    subsidize_build_queue
    subsidize_ship
));


no Moose;
__PACKAGE__->meta->make_immutable;

