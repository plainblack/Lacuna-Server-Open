package Lacuna::DB::Building::Food::Factory::Cheese;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

has '+image' => ( 
    default => 'cheese', 
);

has '+name' => (
    default => 'Cheese Maker',
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
    default => 100,
);

has '+time_to_build' => (
    default => 200,
);

has '+food_consumption' => (
    default => 150,
);

has '+cheese_production' => (
    default => 100,
);

has '+energy_consumption' => (
    default => 75,
);

has '+ore_consumption' => (
    default => 2,
);

has '+water_consumption' => (
    default => 75,
);

has '+waste_production' => (
    default => 125,
);



no Moose;
__PACKAGE__->meta->make_immutable;
