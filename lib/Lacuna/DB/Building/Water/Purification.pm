package Lacuna::DB::Building::Water::Purification;

use Moose;
extends 'Lacuna::DB::Building::Water';

has '+image' => ( 
    default => 'purification', 
);

has '+name' => (
    default => 'Water Purification Plant',
);

has '+food_to_build' => (
    default => -100,
);

has '+energy_to_build' => (
    default => -100,
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
    default => 95,
);

has '+food_production' => (
    default => -5,
);

has '+energy_production' => (
    default => -15,
);

has '+ore_production' => (
    default => -15,
);

has '+water_production' => (
    default => 100,
);

has '+waste_production' => (
    default => 10,
);



no Moose;
__PACKAGE__->meta->make_immutable;
