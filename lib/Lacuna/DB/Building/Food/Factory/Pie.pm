package Lacuna::DB::Building::Food::Factory::Pie;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

has '+image' => ( 
    default => 'pie', 
);

has '+name' => (
    default => 'Lapis Pie Bakery',
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

has '+pie_production' => (
    default => 100,
);

has '+energy_consumption' => (
    default => 50,
);

has '+water_consumption' => (
    default => 20,
);

has '+waste_production' => (
    default => 50,
);



no Moose;
__PACKAGE__->meta->make_immutable;
