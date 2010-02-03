package Lacuna::DB::Building::Food::Reserve;

use Moose;
extends 'Lacuna::DB::Building::Food::Reserve';

has '+image' => ( 
    default => 'food-reserve', 
);

has '+name' => (
    default => 'Food Reserve',
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
    default => 1,
);

has '+energy_consumption' => (
    default => 10,
);

has '+water_consumption' => (
    default => 1,
);

has '+waste_production' => (
    default => 1,
);

has '+food_storage' => (
    default => 1500,
);



no Moose;
__PACKAGE__->meta->make_immutable;
