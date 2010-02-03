package Lacuna::DB::Building::Network19;

use Moose;
extends 'Lacuna::DB::Building';

has '+image' => ( 
    default => 'network19', 
);

has '+name' => (
    default => 'Network 19 Affliate',
);

has '+food_to_build' => (
    default => 100,
);

has '+energy_to_build' => (
    default => 100,
);

has '+ore_to_build' => (
    default => 100,
);

has '+water_to_build' => (
    default => 100,
);

has '+waste_to_build' => (
    default => 100,
);

has '+time_to_build' => (
    default => 200,
);

has '+food_consumption' => (
    default => 30,
);

has '+energy_consumption' => (
    default => 95,
);

has '+ore_consumption' => (
    default => 2,
);

has '+water_consumption' => (
    default => 45,
);

has '+waste_production' => (
    default => 15,
);

has '+happiness_production' => (
    default => 60,
);



no Moose;
__PACKAGE__->meta->make_immutable;
