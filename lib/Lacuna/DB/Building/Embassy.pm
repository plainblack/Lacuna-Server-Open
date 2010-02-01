package Lacuna::DB::Building::Embassy;

use Moose;
extends 'Lacuna::DB::Building';

has '+image' => ( 
    default => 'embassy', 
);

has '+name' => (
    default => 'Embassy',
);

has '+food_to_build' => (
    default => -70,
);

has '+energy_to_build' => (
    default => -70,
);

has '+ore_to_build' => (
    default => -70,
);

has '+water_to_build' => (
    default => -70,
);

has '+waste_to_build' => (
    default => 70,
);

has '+time_to_build' => (
    default => 60,
);

has '+food_production' => (
    default => -25,
);

has '+energy_production' => (
    default => -30,
);

has '+ore_production' => (
    default => -5,
);

has '+water_production' => (
    default => -25,
);

has '+waste_production' => (
    default => 5,
);


no Moose;
__PACKAGE__->meta->make_immutable;
