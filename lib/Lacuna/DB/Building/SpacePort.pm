package Lacuna::DB::Building::SpacePort;

use Moose;
extends 'Lacuna::DB::Building';
use Lacuna::Constants qw(SHIP_TYPES);

__PACKAGE__->add_attributes(
    probe_count                         => { isa => 'Int', default => 0 },
    colony_ship_count                   => { isa => 'Int', default => 0 },
    spy_pod_count                       => { isa => 'Int', default => 0 },
    cargo_ship_count                    => { isa => 'Int', default => 0 },
    space_station_count                 => { isa => 'Int', default => 0 },
    smuggler_ship_count                 => { isa => 'Int', default => 0 },
    mining_platform_ship_count          => { isa => 'Int', default => 0 },
    terraforming_platform_ship_count    => { isa => 'Int', default => 0 },
    gas_giant_settlement_platform_ship_count     => { isa => 'Int', default => 0 },
);

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Ships));
};

sub shipyards {
    my $self = shift;
    return $self->body->get_buildings_of_class('Lacuna::DB::Building::Shipyard');
}

has propulsion_factory => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->body->get_buildings_of_class('Lacuna::DB::Building::Propulsion')->next;
    },
);

sub send_probe {
    my ($self, $star) = @_;
    $self->probe_count($self->probe_count - 1);
    $self->put;
    my $duration = $self->calculate_seconds_from_body_to_star('probe', $self->body, $star);
    return Lacuna::DB::TravelQueue->send(
        simpledb        => $self->simpledb,
        body            => $self->body,
        foreign_star    => $star,
        ship_type       => 'probe',
        direction       => 'outgoing',
        date_arrives    => DateTime->now->add(seconds=>$duration),
    );
}

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
    my $speed_improvement = $propulsion_level * ((100 + $self->empire->species->science_affinity) / 100);
    return $base_speed * ((100 + $speed_improvement) / 100);
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

sub check_for_completed_ships {
    my $self = shift;
    my $shipyards = $self->shipyards;
    while (my $shipyard = $shipyards->next) {
        $shipyard->check_for_completed_ships($self);
    }
}

sub ships_docked {
    my $self = shift;
    my $tally;
    foreach my $type (SHIP_TYPES) {
        my $docked = $type.'_count';
        $tally += $self->$docked;
    }
    return $tally;
}

sub docks_available {
    my $self = shift;
    return ($self->level * 2) - $self->ships_docked;
}

sub is_full {
    my ($self) = @_;
    return $self->docks_available ? 0 : 1;
}

sub add_ship {
    my ($self, $type) = @_;
    my $count = $type.'_count';
    $self->$count( $self->$count + 1);
}


use constant star_to_body_distance_ratio => 100;

use constant ship_speed => {
    probe                               => 1000,
    gas_giant_settlement_platform_ship  => 150,
    terraforming_platform_ship          => 150,
    mining_platform_ship                => 300,
    cargo_ship                          => 300,
    smuggler_ship                       => 450,
    spy_pod                             => 600,
    colony_ship                         => 100,
    space_station                       => 1,
};

use constant controller_class => 'Lacuna::Building::SpacePort';

use constant university_prereq => 3;

use constant image => 'spaceport';

use constant name => 'Space Port';

use constant food_to_build => 160;

use constant energy_to_build => 180;

use constant ore_to_build => 220;

use constant water_to_build => 160;

use constant waste_to_build => 100;

use constant time_to_build => 300;

use constant food_consumption => 10;

use constant energy_consumption => 200;

use constant ore_consumption => 20;

use constant water_consumption => 12;

use constant waste_production => 20;


no Moose;
__PACKAGE__->meta->make_immutable;
