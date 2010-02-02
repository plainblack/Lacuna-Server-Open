package Lacuna::DB::Building::Food::Factory::Soup;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

has '+image' => ( 
    default => 'soup', 
);

has '+name' => (
    default => 'Amalgus Bean Soup Cannery',
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

has '+soup_produced' => (
    default => 110,
);

has '+energy_consumption' => (
    default => 20,
);

has '+ore_consumption' => (
    default => 3,
);

has '+water_consumption' => (
    default => 30,
);

has '+waste_production' => (
    default => 25,
);



no Moose;
__PACKAGE__->meta->make_immutable;
