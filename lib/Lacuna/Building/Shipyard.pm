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
    my $costs = $building->get_ship_costs($type);
    $building->can_build_ship($type, $quantity, $costs);
    $building->build_ship($type, $quantity, $costs);
    return $self->view($empire, $building);
}

sub get_buildable {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    my %buildable;
    my $status = $empire->get_full_status;
    foreach my $type (SHIP_TYPES) {
        my $can = eval{$building->can_build_ship($type, 1)};
        $buildable{$type} = {
            cost    => $building->get_ship_costs($type),
            can     => ($can) ? 1 : 0,
            reason  => $@,
        };
    }
    my $docks;
    my $ports = $building->spaceports;
    while (my $port = $ports->next) {
        $docks += $port->docks_available;
    }
    return { buildable=>\%buildable, docks_available=>$docks, status=>$status};
}


__PACKAGE__->register_rpc_method_names(qw(get_buildable build_ship));


no Moose;
__PACKAGE__->meta->make_immutable;

