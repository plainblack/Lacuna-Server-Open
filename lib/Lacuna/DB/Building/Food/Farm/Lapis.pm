package Lacuna::DB::Building::Food::Farm::Lapis;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

has '+image' => ( 
    default => 'lapis', 
);

has '+name' => (
    default => 'Lapis Orchard',
);

has '+food_to_build' => (
    default => 10,
);

has '+energy_to_build' => (
    default => 100,
);

has '+ore_to_build' => (
    default => 55,
);

has '+water_to_build' => (
    default => 10,
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

has '+lapis_production' => (
    default => 75,
);

has '+energy_consumption' => (
    default => 2,
);

has '+ore_consumption' => (
    default => 10,
);

has '+water_consumption' => (
    default => 10,
);

has '+waste_production' => (
    default => 50,
);



no Moose;
__PACKAGE__->meta->make_immutable;
