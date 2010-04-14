package Lacuna::Building::Shipyard;

use Moose;
extends 'Lacuna::Building';
use Lacuna::Constants qw(SHIP_TYPES);

sub app_url {
    return '/shipyard';
}

sub model_class {
    return 'Lacuna::DB::Building::Shipyard';
}


around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    my $out = $orig->($self, $empire, $building);
    return $out unless $building->level > 0;
    $building->check_for_completed_ships;
    $out->{ship_build_queue} = $building->format_ship_builds;
    return $out;
};

sub build_ship {
    my ($self, $session_id, $building_id, $type, $quantity) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
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
    return {
        ship_build_queue    => $building->format_ship_builds,
        status              => $empire->get_status,
    };
}

sub get_buildable {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    my %buildable;
    $building->body->tick;
    my $docks;
    my $ports = $building->spaceports;
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


__PACKAGE__->register_rpc_method_names(qw(get_buildable build_ship));


no Moose;
__PACKAGE__->meta->make_immutable;

