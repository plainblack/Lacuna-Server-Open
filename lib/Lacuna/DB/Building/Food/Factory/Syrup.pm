package Lacuna::DB::Building::Food::Factory::Syrup;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

has '+food_produced' => ( 
    default => 'Syrup',
);

has '+image' => ( 
    default => 'syrup0',
);

has '+name' => (
    default => 'Algae Syrup Bottler',
);

has '+converts_food' = (
    default => 'Algae',
);

has '+energy_to_build' => (
    default => -100,
);

has '+food_to_build' => (
    default => -10,
);

has '+water_to_build' => (
    default => -100,
);

has '+ore_to_build' => (
    default => -100,
);

has '+waste_to_build' => (
    default => 100,
);

has '+food_production' => (
    default => 5,
);

has '+energy_production' => (
    default => 3,
);

has '+ore_production' => (
    default => -1,
);

has '+water_production' => (
    default => -2,
);

has '+waste_production' => (
    default => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable;
