package Lacuna::RPC::Building::MiningMinistry;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/miningministry';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Ore::Ministry';
}

sub view_ships {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({ body_id => $self->body_id, task => { in => ['Mining', 'Docked']}, type => 'cargo_ship' });
    my @fleet;
    while (my $ship = $ships->next) {
        push @fleet, {
            id          => $ship->id,
            name        => $ship->name,
            speed       => $ship->speed,
            hold_size   => $ship->hold_size,
            task        => $ship->task,
        };
    }
    return {
        ships           => \@fleet,
        status          => $empire->get_status,
    };
}

sub view_platforms {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    my $platforms = $building->platforms;
    my @fleet;
    while (my $platform = $platforms->next) {
        push @fleet, {
            id                              => $platform->id,
            asteroid                        => {
                id      => $platform->asteroid_id,
                name    => $platform->asteroid->name,
            },
            rutile_hour                     => $platform->rutile_hour,
            chromite_hour                   => $platform->chromite_hour,
            chalcopyrite_hour               => $platform->chalcopyrite_hour,
            galena_hour                     => $platform->galena_hour,
            gold_hour                       => $platform->gold_hour,
            uraninite_hour                  => $platform->uraninte_hour,
            bauxite_hour                    => $platform->bauxite_hour,
            goethite_hour                   => $platform->goethite_hour,
            halite_hour                     => $platform->halite_hour,
            gypsum_hour                     => $platform->gypsum_hour,
            trona_hour                      => $platform->trona_hour,
            kerogen_hour                    => $platform->kerogen_hour,
            methane_hour                    => $platform->methane_hour,
            anthracite_hour                 => $platform->anthracite_hour,
            sulfur_hour                     => $platform->sulfur_hour,
            zircon_hour                     => $platform->zircon_hour,
            monazite_hour                   => $platform->monazite_hour,
            fluorite_hour                   => $platform->fluorite_hour,
            beryl_hour                      => $platform->beryl_hour,
            magnetite_hour                  => $platform->magnetite_hour,  
            production_capacity             => $platform->percent_platform_capacity,
            shipping_capacity               => $platform->percent_ship_capacity,
        };
    }
    return {
        platforms       => \@fleet,
        max_platforms   => $building->max_platforms,
        status          => $empire->get_status,
    };
}

sub abandon_platform {
    my ($self, $session_id, $building_id, $platform_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    my $platform = Lacuna->db->resultset('Lacuna::DB::Result::MiningPlatforms')->find($platform_id);
    unless (defined $platform) {
        confess [1002, "Platform not found."];
    }
    unless ($platform->planet_id eq $building->body_id) {
        confess [1013, "You can't abandon a platform that is not yours."];
    }
    $building->remove_platform($platform);
    return {
        status  => $empire->get_status,
    };
}

sub add_cargo_ship_to_fleet {
    my ($self, $session_id, $building_id, $ship_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($ship_id);
    unless (defined $ship) {
        confess [1002, "Ship not found."];
    }
    unless ($ship->task eq 'Docked') {
        confess [1009, "That ship is not available."];
    }
    unless ($ship->body_id eq $building->body_id) {
        confess [1013, "You can't manage a ship that is not yours."];
    }
    $building->add_ship($ship);
    return {
        status  => $empire->get_status,
    };
}

sub remove_cargo_ship_from_fleet {
    my ($self, $session_id, $building_id, $ship_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($ship_id);
    unless (defined $ship) {
        confess [1002, "Ship not found."];
    }
    unless ($ship->task eq 'Mining') {
        confess [1009, "That ship is not mining."];
    }
    unless ($ship->body_id eq $building->body_id) {
        confess [1013, "You can't manage a ship that is not yours."];
    }
    $building->send_ship_home($ship);
    return {
        status  => $empire->get_status,
    };
}


__PACKAGE__->register_rpc_method_names(qw(view_platforms view_ships abandon_platform remove_cargo_ships_from_fleet add_cargo_ships_to_fleet));

no Moose;
__PACKAGE__->meta->make_immutable;

