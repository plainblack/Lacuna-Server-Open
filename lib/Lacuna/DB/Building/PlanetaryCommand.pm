package Lacuna::DB::Building::PlanetaryCommand;

use Moose;
extends 'Lacuna::DB::Building';

has '+image' => ( 
    default => 'planetary-command', 
);

has '+name' => (
    default => 'Planetary Command',
);

has '+food_to_build' => (
    default => 1000,
);

has '+energy_to_build' => (
    default => 1000,
);

has '+ore_to_build' => (
    default => 1000,
);

has '+water_to_build' => (
    default => 1000,
);

has '+waste_to_build' => (
    default => 1000,
);

has '+time_to_build' => (
    default => 600,
);

has '+food_production' => (
    default => 100,
);

has '+energy_production' => (
    default => 100,
);

has '+ore_production' => (
    default => 100,
);

has '+water_production' => (
    default => 100,
);

has '+waste_production' => (
    default => 10,
);

has '+food_storage' => (
    default => 300,
);

has '+energy_storage' => (
    default => 300,
);

has '+ore_storage' => (
    default => 300,
);

has '+water_storage' => (
    default => 300,
);

has '+waste_storage' => (
    default => 300,
);



no Moose;
__PACKAGE__->meta->make_immutable;
