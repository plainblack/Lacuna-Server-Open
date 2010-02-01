package Lacuna::DB::Building::Ore::Refinery;

use Moose;
extends 'Lacuna::DB::Building::Refinery';

has '+image' => ( 
    default => 'refinery', 
);

has '+name' => (
    default => 'Ore Refinery',
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
    default => -100,
);

has '+time_to_build' => (
    default => 200,
);

has '+food_production' => (
    default => -25,
);

has '+energy_production' => (
    default => -80,
);

has '+ore_production' => (
    default => 0,
);

has '+water_production' => (
    default => -15,
);

has '+waste_production' => (
    default => 70,
);



no Moose;
__PACKAGE__->meta->make_immutable;
