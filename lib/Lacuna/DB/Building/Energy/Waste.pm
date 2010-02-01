package Lacuna::DB::Building::Energy::Waste;

use Moose;
extends 'Lacuna::DB::Building::Energy';

has '+image' => ( 
    default => 'waste', 
);

has '+name' => (
    default => 'Waste Energy Plant',
);

has '+food_to_build' => (
    default => -100,
);

has '+energy_to_build' => (
    default => -10,
);

has '+ore_to_build' => (
    default => -100,
);

has '+water_to_build' => (
    default => -100,
);

has '+waste_to_build' => (
    default => 20,
);

has '+time_to_build' => (
    default => 95,
);

has '+food_production' => (
    default => -10,
);

has '+energy_production' => (
    default => 145,
);

has '+ore_production' => (
    default => -5,
);

has '+water_production' => (
    default => -10,
);

has '+waste_production' => (
    default => -90,
);



no Moose;
__PACKAGE__->meta->make_immutable;
