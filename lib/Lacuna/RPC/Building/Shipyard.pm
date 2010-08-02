package Lacuna::RPC::Building::Shipyard;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';
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
    my $building = $self->get_building($empire, $building_id);
    $building->is_offline;
    my $body = $building->body;
    $page_number ||= 1;
    my @building;
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        { shipyard_id => $building->id, task => 'building' },
        { order_by    => 'date_available', rows => 25, page => $page_number },
        );
    while (my $ship = $ships->next) {
        push @building, {
            type            => $ship->type,
            date_completed  => $ship->date_available_formatted,
        }
    }
    return {
        status                      => $self->format_status($empire, $body),
        number_of_ships_building    => $ships->pager->total_entries,
        ships_building              => \@building,
    };
}

sub build_ship {
    my ($self, $session_id, $building_id, $type) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $body = $building->body;
    my $costs = $building->get_ship_costs($type);
    $building->can_build_ship($type, $costs);
    foreach my $key (keys %{ $costs }) {
        next if $key eq 'seconds';
        if ($key eq 'waste') {
            $body->add_waste($costs->{waste});
        }
        else {
            my $spend = 'spend_'.$key;
            $body->$spend($costs->{$key});
        }
    }
    $body->update;
    $building->build_ship($type, $costs->{seconds});
    return $self->view_build_queue($empire, $building);
}

sub get_buildable {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my %buildable;
    my $docks;
    my $ports = $building->body->get_buildings_of_class('Lacuna::DB::Result::Building::SpacePort');
    while (my $port = $ports->next) {
        $docks += $port->docks_available;
    }
    foreach my $type (SHIP_TYPES) {
        my $can = eval{$building->can_build_ship($type)};
        $buildable{$type} = {
            attributes  => {
                speed       =>  $building->get_ship_speed($type),
                hold_size   =>  $building->get_ship_hold_size($type),
            },
            cost        => $building->get_ship_costs($type),
            can         => ($can) ? 1 : 0,
            reason      => $@,
        };
    }
    return { buildable=>\%buildable, docks_available=>$docks, status=>$self->format_status($empire, $building->body)};
}


__PACKAGE__->register_rpc_method_names(qw(get_buildable build_ship view_build_queue));


no Moose;
__PACKAGE__->meta->make_immutable;

