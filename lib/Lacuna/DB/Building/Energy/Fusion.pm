package Lacuna::DB::Building::Energy::Fusion;

use Moose;
extends 'Lacuna::DB::Building::Energy';

has '+image' => ( 
    default => 'fusion', 
);

has '+name' => (
    default => 'Fusion Energy Plant',
);

has '+food_to_build' => (
    default => -500,
);

has '+energy_to_build' => (
    default => -650,
);

has '+ore_to_build' => (
    default => -575,
);

has '+water_to_build' => (
    default => -480,
);

has '+waste_to_build' => (
    default => 200,
);

has '+time_to_build' => (
    default => 790,
);

has '+food_production' => (
    default => -5,
);

has '+energy_production' => (
    default => 467,
);

has '+ore_production' => (
    default => -30,
);

has '+water_production' => (
    default => -60,
);

has '+waste_production' => (
    default => 8,
);



no Moose;
__PACKAGE__->meta->make_immutable;
