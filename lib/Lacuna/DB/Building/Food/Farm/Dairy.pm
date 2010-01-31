package Lacuna::DB::Building::Food::Farm::Dairy;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

has '+image' => ( 
    default => 'dairy', 
);

has '+name' => (
    default => 'Dairy Farm',
);

has '+food_produced' (
    default => 'Milk',
);

has '+food_to_build' => (
    default => -200,
);

has '+energy_to_build' => (
    default => -100,
);

has '+ore_to_build' => (
    default => -150,
);

has '+water_to_build' => (
    default => -60,
);

has '+waste_to_build' => (
    default => 50,
);

has '+time_to_build' => (
    default => 80,
);

has '+food_production' => (
    default => 32,
);

has '+energy_production' => (
    default => -3,
);

has '+ore_production' => (
    default => -3,
);

has '+water_production' => (
    default => -10,
);

has '+waste_production' => (
    default => 48,
);



no Moose;
__PACKAGE__->meta->make_immutable;
