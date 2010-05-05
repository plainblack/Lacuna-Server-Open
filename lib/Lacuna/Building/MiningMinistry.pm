package Lacuna::Building::MiningMinistry;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/miningministry';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Ore::Ministry';
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    my $out = $orig->($self, $empire, $building);
    $out->{mining} = {
        ships_in_fleet      => $building->ship_count,
        max_ships           => $building->max_ships,
        platforms_in_fleet  => $building->platform_count,
        max_platforms       => $building->max_platforms,
        production          => {
                rutile_hour                     => $building->rutile_hour,
                chromite_hour                   => $building->chromite_hour,
                chalcopyrite_hour               => $building->chalcopyrite_hour,
                galena_hour                     => $building->galena_hour,
                gold_hour                       => $building->gold_hour,
                uraninite_hour                  => $building->uraninte_hour,
                bauxite_hour                    => $building->bauxite_hour,
                goethite_hour                   => $building->goethite_hour,
                halite_hour                     => $building->halite_hour,
                gypsum_hour                     => $building->gypsum_hour,
                trona_hour                      => $building->trona_hour,
                kerogen_hour                    => $building->kerogen_hour,
                methane_hour                    => $building->methane_hour,
                anthracite_hour                 => $building->anthracite_hour,
                sulfur_hour                     => $building->sulfur_hour,
                zircon_hour                     => $building->zircon_hour,
                monazite_hour                   => $building->monazite_hour,
                fluorite_hour                   => $building->fluorite_hour,
                beryl_hour                      => $building->beryl_hour,
                magnetite_hour                  => $building->magnetite_hour,  
        },
        production_capacity    => $building->percent_platform_capacity,
        shipping_capacity      => $building->percent_ship_capacity,
    };
    return $out;
};

sub abandon_platform {
    my ($self, $session_id, $building_id, $asteroid_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    my $asteroid = $self->simpledb->domain('Lacuna::DB::Result::Body::Asteroid')->find($asteroid_id);
    unless (defined $asteroid) {
        confess [1002, "Asteroid not found."];
    }
    $building->remove_platform($asteroid)->put;
    return {
        status  => $empire->get_status,
    };
}

sub add_cargo_ships_to_fleet {
    my ($self, $session_id, $building_id, $count) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    $count ||= 1;
    $building->can_add_ships($count);
    $building->add_ships($count)->put;
    return {
        status  => $empire->get_status,
    };
}

sub remove_cargo_ships_from_fleet {
    my ($self, $session_id, $building_id, $count) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    $count ||= 1;
    $building->can_remove_ships($count);
    $building->send_ships_home($count)->put;
    return {
        status  => $empire->get_status,
    };
}

sub view_asteroids {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    my %asteroids;
    foreach my $id (@{$self->asteroid_ids}) {
        unless (exists $asteroids{$id}) {
            my $asteroid = $self->simpledb->domain('Lacuna::DB::Result::Body::Asteroid')->find($id);
            $asteroids{$id}{object} = $asteroid;
        }
        $asteroids{$id}{platform_count}++;
    }
    my @out;
    foreach my $id (keys %asteroids) {
        my $roid = $asteroids{$id}{object};
        push @out, {
            name            => $roid->name,
            id              => $roid->id,
            x               => $roid->x,
            y               => $roid->y,
            z               => $roid->z,
            orbit           => $roid->orbit,
            image           => $roid->image,
            platform_count  => $asteroids{$id}{platform_count},
        };
    }
    return {
        status      => $empire->get_status,
        asteroids   => \@out,
    };
}

__PACKAGE__->register_rpc_method_names(qw(view_asteroids abandon_platform remove_cargo_ships_from_fleet add_cargo_ships_to_fleet));

no Moose;
__PACKAGE__->meta->make_immutable;

