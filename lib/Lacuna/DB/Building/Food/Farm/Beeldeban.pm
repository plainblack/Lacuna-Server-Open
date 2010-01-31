package Lacuna::DB::Building::Food::Farm::Beeldeban;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

has '+image' => ( 
    default => 'beeldeban', 
);

has '+name' => (
    default => 'Beeldeban Herder',
);

has '+food_produced' (
    default => 'Beeldeban Beetles',
);

has '+food_to_build' => (
    default => -100,
);

has '+energy_to_build' => (
    default => -100,
);

has '+ore_to_build' => (
    default => -125,
);

has '+water_to_build' => (
    default => -50,
);

has '+waste_to_build' => (
    default => 35,
);

has '+time_to_build' => (
    default => 80,
);

has '+food_production' => (
    default => 22,
);

has '+energy_production' => (
    default => -2,
);

has '+ore_production' => (
    default => -4,
);

has '+water_production' => (
    default => -3,
);

has '+waste_production' => (
    default => 23,
);



no Moose;
__PACKAGE__->meta->make_immutable;
