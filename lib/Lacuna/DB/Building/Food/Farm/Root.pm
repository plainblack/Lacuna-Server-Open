package Lacuna::DB::Building::Food::Farm::Root;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

has '+image' => ( 
    default => 'root', 
);

has '+name' => (
    default => 'Denton Root Patch',
);

has '+food_produced' (
    default => 'Denton Roots',
);

has '+food_to_build' => (
    default => -10,
);

has '+energy_to_build' => (
    default => -100,
);

has '+ore_to_build' => (
    default => -55,
);

has '+water_to_build' => (
    default => -10,
);

has '+waste_to_build' => (
    default => 10,
);

has '+time_to_build' => (
    default => 60,
);

has '+food_production' => (
    default => 43,
);

has '+energy_production' => (
    default => -1,
);

has '+ore_production' => (
    default => -1,
);

has '+water_production' => (
    default => -8,
);

has '+waste_production' => (
    default => 7,
);



no Moose;
__PACKAGE__->meta->make_immutable;
