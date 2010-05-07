package Lacuna::Role::Distanced;

use Moose::Role;
requires 'body';

use constant star_to_body_distance_ratio => 100;

use constant ship_speed => {
    probe                               => 500,
    gas_giant_settlement_platform_ship  => 70,
    terraforming_platform_ship          => 75,
    mining_platform_ship                => 100,
    cargo_ship                          => 150,
    smuggler_ship                       => 250,
    spy_pod                             => 300,
    colony_ship                         => 50,
    space_station                       => 1,
};


has propulsion_factory => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->body->get_building_of_class('Lacuna::DB::Result::Building::Propulsion');
    },
);

sub calculate_distance_from_star_to_star {
    my ($self, $star1, $star2) = @_;
    return sqrt(abs($star1->x - $star2->x)**2 + abs($star1->y - $star2->y)**2 + abs($star1->z - $star2->z)**2) + $self->star_to_body_distance_ratio;
}

sub calculate_distance_from_body_to_star {
    my ($self, $body, $star) = @_;
    my $stellar = $self->calculate_distance_from_star_to_star($body->star, $star);
    my $orbital = $self->calculate_distance_from_orbit_to_orbit(0, $body->orbit);
    return $stellar + $orbital;
}

sub calculate_distance_from_body_to_body {
    my ($self, $body1, $body2) = @_;
    my $stellar = $self->calculate_distance_from_star_to_star($body1->star, $body2->star);
    my $orbital1 = $self->calculate_distance_from_orbit_to_orbit(0, $body1->orbit);
    my $orbital2 = $self->calculate_distance_from_orbit_to_orbit(0, $body2->orbit);
    return $stellar + $orbital1 + $orbital2;
}

sub calculate_distance_from_orbit_to_orbit {
    my ($self, $orbit1, $orbit2) = @_;
    return abs($orbit1 - $orbit2);
}

sub get_ship_speed {
    my ($self, $type) = @_;
    my $base_speed = $self->ship_speed->{$type};
    my $propulsion_level = (defined $self->propulsion_factory) ? $self->propulsion_factory->level : 0;
    my $speed_improvement = $propulsion_level * ((100 + $self->body->empire->species->science_affinity) / 100);
    return sprintf('%.0f', $base_speed * ((100 + $speed_improvement) / 100));
}

sub calculate_seconds_from_body_to_star {
    my ($self, $ship_type, $body, $star) = @_;
    my $ship_speed = $self->get_ship_speed($ship_type);
    my $distance = $self->calculate_distance_from_body_to_star($body, $star);
    my $hours = $distance / $ship_speed;
    my $seconds = 60 * 60 * $hours;
    return sprintf('%.0f', $seconds);
}

sub calculate_seconds_from_body_to_body {
    my ($self, $ship_type, $body1, $body2) = @_;
    my $ship_speed = $self->get_ship_speed($ship_type);
    my $distance = $self->calculate_distance_from_body_to_body($body1, $body2);
    my $hours = $distance / $ship_speed;
    my $seconds = 60 * 60 * $hours;
    return sprintf('%.0f', $seconds);
}



1;
