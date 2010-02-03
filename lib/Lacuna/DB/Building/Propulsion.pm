package Lacuna::DB::Building::Propulsion;

use Moose;
extends 'Lacuna::DB::Building';

has '+image' => ( 
    default => 'propulsion', 
);

has '+name' => (
    default => 'Propulsion System Factory',
);

has '+food_to_build' => (
    default => 150,
);

has '+energy_to_build' => (
    default => 225,
);

has '+ore_to_build' => (
    default => 225,
);

has '+water_to_build' => (
    default => 100,
);

has '+waste_to_build' => (
    default => 150,
);

has '+time_to_build' => (
    default => 125,
);

has '+food_consumption' => (
    default => 10,
);

has '+energy_consumption' => (
    default => 100,
);

has '+ore_consumption' => (
    default => 100,
);

has '+water_consumption' => (
    default => 50,
);

has '+waste_production' => (
    default => 75,
);


no Moose;
__PACKAGE__->meta->make_immutable;
