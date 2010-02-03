package Lacuna::DB::Building::Food::Factory::Chip;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

has '+image' => ( 
    default => 'chip', 
);

has '+name' => (
    default => 'Denton Root Chip Frier',
);

has '+food_to_build' => (
    default => 100,
);

has '+energy_to_build' => (
    default => 100,
);

has '+ore_to_build' => (
    default => 100,
);

has '+water_to_build' => (
    default => 100,
);

has '+waste_to_build' => (
    default => 100,
);

has '+time_to_build' => (
    default => 200,
);

has '+food_consumption' => (
    default => 150,
);

has '+chip_production' => (
    default => 100,
);

has '+energy_consumption' => (
    default => 25,
);

has '+ore_consumption' => (
    default => 25,
);

has '+water_consumption' => (
    default => 25,
);

has '+waste_production' => (
    default => 50,
);



no Moose;
__PACKAGE__->meta->make_immutable;
