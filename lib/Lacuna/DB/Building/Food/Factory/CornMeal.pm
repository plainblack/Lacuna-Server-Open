package Lacuna::DB::Building::Food::Factory::CornMeal;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

has '+image' => ( 
    default => 'cornmeal', 
);

has '+name' => (
    default => 'Corn Meal Grinder',
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

has '+food_production' => (
    default => 125,
);

has '+energy_consumption' => (
    default => 50,
);

has '+water_consumption' => (
    default => 25,
);

has '+waste_production' => (
    default => 50,
);



no Moose;
__PACKAGE__->meta->make_immutable;
