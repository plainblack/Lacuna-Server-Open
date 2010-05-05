package Lacuna::Building::Shipyard;

use Moose;
extends 'Lacuna::Building';
use Lacuna::Constants qw(SHIP_TYPES);

sub app_url {
    return '/shipyard';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Shipyard';
}

sub view_build_queue {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    $building->is_offline;
    my $body = $building->body;
    my $spaceport = $body->spaceport;
    $spaceport->check_for_completed_ships;
    $spaceport->save_changed_ports;
    $page_number ||= 1;
    my $count = $self->simpledb->domain('Lacuna::DB::Result::ShipBuilds')->count(where=>{shipyard_id=>$building->id});
    my @building;
    my $ships = $self->simpledb->domain('Lacuna::DB::Result::ShipBuilds')->search(
        where       => { shipyard_id => $building->id, date_completed => ['>', DateTime->now ] },
        order_by    => ['date_completed'],
        )->paginate(25, $page_number);
    while (my $ship = $ships->next) {
        push @building, {
            type            => $ship->type,
            date_completed  => $ship->date_completed_formatted,
        }
    }
    return {
        status                      => $empire->get_status,
        number_of_ships_building    => $count,
        ships_building              => \@building,
    };
}

sub build_ship {
    my ($self, $session_id, $building_id, $type, $quantity) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    $building->is_offline;
    my $body = $building->body;
    $body->tick;
    $building = $empire->get_building($self->model_class, $building_id); #might be stale
    $building->body($body);
    my $costs = $building->get_ship_costs($type);
    $building->can_build_ship($type, $quantity, $costs);
    foreach my $key (keys %{ $costs }) {
        next if $key eq 'seconds';
        if ($key eq 'waste') {
            $body->add_waste($costs->{waste} * $quantity);
        }
        else {
            my $spend = 'spend_'.$key;
            $body->$spend($costs->{$key} * $quantity);
        }
    }
    $body->put;
    $empire->trigger_full_update;
    $building->build_ship($type, $quantity, $costs->{seconds});
    return $self->view_build_queue($empire, $building);
}

sub get_buildable {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    $building->is_offline;
    my %buildable;
    $building->body->tick;
    my $docks;
    my $ports = $building->body->get_buildings_of_class('Lacuna::DB::Result::Building::SpacePort');
    my $port_cached;
    while (my $port = $ports->next) {
        $docks += $port->docks_available;
        $port_cached = $port;
    }
    foreach my $type (SHIP_TYPES) {
        my $can = eval{$building->can_build_ship($type, 1)};
        $buildable{$type} = {
            attributes  => {
                speed   =>  $port_cached->get_ship_speed($type),
            },
            cost        => $building->get_ship_costs($type),
            can         => ($can) ? 1 : 0,
            reason      => $@,
        };
    }
    return { buildable=>\%buildable, docks_available=>$docks, status=>$empire->get_status};
}


__PACKAGE__->register_rpc_method_names(qw(get_buildable build_ship view_build_queue));


no Moose;
__PACKAGE__->meta->make_immutable;

