package Lacuna::DB::Building::Ore::Platform;

use Moose;
extends 'Lacuna::DB::Building::Ore';

has '+image' => ( 
    default => 'mining-platform', 
);

has '+name' => (
    default => 'Mining Platform',
);

has '+food_to_build' => (
    default => -500,
);

has '+energy_to_build' => (
    default => -500,
);

has '+ore_to_build' => (
    default => -50,
);

has '+water_to_build' => (
    default => -500,
);

has '+waste_to_build' => (
    default => 425,
);

has '+time_to_build' => (
    default => 500,
);

has '+food_production' => (
    default => -5,
);

has '+energy_production' => (
    default => -50,
);

has '+ore_production' => (
    default => 10,
);

has '+water_production' => (
    default => -50,
);

has '+waste_production' => (
    default => 15,
);



no Moose;
__PACKAGE__->meta->make_immutable;
