package Lacuna::DB::Building::Energy::Singularity;

use Moose;
extends 'Lacuna::DB::Building::Energy';

has '+image' => ( 
    default => 'singularity', 
);

has '+name' => (
    default => 'Singularity Energy Plant',
);

has '+food_to_build' => (
    default => -1100,
);

has '+energy_to_build' => (
    default => -1205,
);

has '+ore_to_build' => (
    default => -2350,
);

has '+water_to_build' => (
    default => -1190,
);

has '+waste_to_build' => (
    default => 1475,
);

has '+time_to_build' => (
    default => 1300,
);

has '+food_consumption' => (
    default => 27,
);

has '+energy_consumption' => (
    default => 350,
);

has '+energy_production' => (
    default => 799,
);

has '+ore_consumption' => (
    default => 23,
);

has '+water_consumption' => (
    default => 25,
);

has '+waste_production' => (
    default => 1,
);



no Moose;
__PACKAGE__->meta->make_immutable;
