package Lacuna::DB::Building::GasGiantPlatform;

use Moose;
extends 'Lacuna::DB::Building';

has '+image' => ( 
    default => 'gas-giant-platform', 
);

has '+name' => (
    default => 'Gas Giant Settlement Platform',
);

has '+food_to_build' => (
    default => -1000,
);

has '+energy_to_build' => (
    default => -1000,
);

has '+ore_to_build' => (
    default => -1000,
);

has '+water_to_build' => (
    default => -1000,
);

has '+waste_to_build' => (
    default => 1000,
);

has '+time_to_build' => (
    default => 600,
);

has '+food_production' => (
    default => -45,
);

has '+energy_production' => (
    default => -45,
);

has '+ore_production' => (
    default => -45,
);

has '+water_production' => (
    default => -45,
);

has '+waste_production' => (
    default => 100,
);

no Moose;
__PACKAGE__->meta->make_immutable;
