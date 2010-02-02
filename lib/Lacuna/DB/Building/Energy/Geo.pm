package Lacuna::DB::Building::Energy::Geo;

use Moose;
extends 'Lacuna::DB::Building::Energy';

has '+image' => ( 
    default => 'geo', 
);

has '+name' => (
    default => 'Geo Energy Plant',
);

has '+food_to_build' => (
    default => -100,
);

has '+energy_to_build' => (
    default => -10,
);

has '+ore_to_build' => (
    default => -100,
);

has '+water_to_build' => (
    default => -100,
);

has '+waste_to_build' => (
    default => 20,
);

has '+time_to_build' => (
    default => 130,
);

has '+food_consumption' => (
    default => 2,
);

has '+energy_consumption' => (
    default => 40,
);

has '+energy_production' => (
    default => 141,
);

has '+ore_consumption' => (
    default => 12,
);

has '+water_consumption' => (
    default => 7,
);

has '+waste_production' => (
    default => 4,
);



no Moose;
__PACKAGE__->meta->make_immutable;
