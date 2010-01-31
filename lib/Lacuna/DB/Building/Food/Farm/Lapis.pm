package Lacuna::DB::Building::Food::Farm::Lapis;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

has '+image' => ( 
    default => 'lapis', 
);

has '+name' => (
    default => 'Lapis Orchard',
);

has '+food_produced' (
    default => 'Lapis',
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

has '+food_production' => (
    default => 70,
);

has '+energy_production' => (
    default => -2,
);

has '+ore_production' => (
    default => -10,
);

has '+water_production' => (
    default => -10,
);

has '+waste_production' => (
    default => 50,
);



no Moose;
__PACKAGE__->meta->make_immutable;
