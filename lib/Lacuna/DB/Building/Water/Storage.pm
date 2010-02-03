package Lacuna::DB::Building::Water::Storage;

use Moose;
extends 'Lacuna::DB::Building::Water';

has '+image' => ( 
    default => 'water-storage', 
);

has '+name' => (
    default => 'Water Storage',
);

has '+food_to_build' => (
    default => 25,
);

has '+energy_to_build' => (
    default => 25,
);

has '+ore_to_build' => (
    default => 25,
);

has '+water_to_build' => (
    default => 25,
);

has '+waste_to_build' => (
    default => 25,
);

has '+time_to_build' => (
    default => 100,
);

has '+food_consumption' => (
    default => 2,
);

has '+energy_consumption' => (
    default => 5,
);

has '+ore_consumption' => (
    default => 5,
);

has '+water_consumption' => (
    default => 1,
);

has '+waste_production' => (
    default => 1,
);

has '+water_storage' => (
    default => 1500,
);



no Moose;
__PACKAGE__->meta->make_immutable;
