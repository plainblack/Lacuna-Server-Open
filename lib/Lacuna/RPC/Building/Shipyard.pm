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
    };
}


sub subsidize_build_queue {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $body = $building->body;

    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        { shipyard_id => $building->id, task => 'building' }
        );

    my $cost = $ships->count;
    unless ($empire->essentia >= $cost) {
        confess [1011, "Not enough essentia."];    
    }

    $empire->spend_essentia($cost, 'ship build subsidy after the fact');    
    $empire->update;

    while (my $ship = $ships->next) {
        $ship->finish_construction;
    }
 
    return $self->view($empire, $building);
}


sub build_ship {
    my ($self, $session_id, $building_id, $type) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $body = $building->body;
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type => $type});
    my $costs = $building->get_ship_costs($ship);
    $building->can_build_ship($ship, $costs);
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
    $building->build_ship($ship, $costs->{seconds});
    return $self->view_build_queue($empire, $building);
}



sub get_buildable {
    my ($self, $session_id, $building_id, $tag) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my %buildable;
    my $docks;
    my $ports = $building->body->get_buildings_of_class('Lacuna::DB::Result::Building::SpacePort');
    while (my $port = $ports->next) {
        $docks += $port->docks_available;
    }
    foreach my $type (SHIP_TYPES) {
        my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>$type});
        my @tags = $ship->build_tags;
        if ($tag) {
            next unless ($tag ~~ \@tags);
        }
        my $can = eval{$building->can_build_ship($ship)};
        $buildable{$type} = {
            attributes  => {
                speed       =>  $building->set_ship_speed($ship),
                stealth     =>  $building->set_ship_stealth($ship),
                hold_size   =>  $building->set_ship_hold_size($ship),
            },
            tags        => \@tags,
            cost        => $building->get_ship_costs($ship),
            can         => ($can) ? 1 : 0,
            reason      => $@,
            type_human  => $ship->type_formatted,
        };
    }
    return { buildable=>\%buildable, docks_available=>$docks, status=>$self->format_status($empire, $building->body)};
}


__PACKAGE__->register_rpc_method_names(qw(get_buildable build_ship view_build_queue subsidize_build_queue));


no Moose;
__PACKAGE__->meta->make_immutable;

