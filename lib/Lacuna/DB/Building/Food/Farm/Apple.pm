package Lacuna::DB::Building::Food::Farm::Apple;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

has '+image' => ( 
    default => 'apple', 
);

has '+name' => (
    default => 'Apple Orchard',
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
    default => 5,
);

has '+time_to_build' => (
    default => 60,
);

has '+food_consumption' => (
    default => 5,
);

has '+apple_production' => (
    default => 46,
);

has '+energy_consumption' => (
    default => 1,
);

has '+ore_consumption' => (
    default => 1,
);

has '+water_consumption' => (
    default => 9,
);

has '+waste_production' => (
    default => 16,
);

has '+waste_consumption' => (
    default => 3,
);



no Moose;
__PACKAGE__->meta->make_immutable;
