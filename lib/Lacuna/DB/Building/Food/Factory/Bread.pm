package Lacuna::DB::Building::Food::Factory::Bread;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

has '+image' => ( 
    default => 'bread', 
);

has '+name' => (
    default => 'Bread Bakery',
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

has '+bread_production' => (
    default => 75,
);

has '+energy_consumption' => (
    default => 50,
);

has '+water_consumption' => (
    default => 25,
);

has '+waste_production' => (
    default => 28,
);



no Moose;
__PACKAGE__->meta->make_immutable;
