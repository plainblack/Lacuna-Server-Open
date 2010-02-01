package Lacuna::DB::Building::SpacePort;

use Moose;
extends 'Lacuna::DB::Building';

has '+image' => ( 
    default => 'space-port', 
);

has '+name' => (
    default => 'Space Port',
);

has '+food_to_build' => (
    default => -800,
);

has '+energy_to_build' => (
    default => -900,
);

has '+ore_to_build' => (
    default => -500,
);

has '+water_to_build' => (
    default => -500,
);

has '+waste_to_build' => (
    default => 400,
);

has '+time_to_build' => (
    default => 850,
);

has '+food_production' => (
    default => -100,
);

has '+energy_production' => (
    default => -100,
);

has '+ore_production' => (
    default => -20,
);

has '+water_production' => (
    default => -20,
);

has '+waste_production' => (
    default => 20,
);


no Moose;
__PACKAGE__->meta->make_immutable;
