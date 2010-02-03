package Lacuna::DB::Building::Security;

use Moose;
extends 'Lacuna::DB::Building';

has '+image' => ( 
    default => 'security', 
);

has '+name' => (
    default => 'Security Ministry',
);

has '+food_to_build' => (
    default => 70,
);

has '+energy_to_build' => (
    default => 70,
);

has '+ore_to_build' => (
    default => 70,
);

has '+water_to_build' => (
    default => 70,
);

has '+waste_to_build' => (
    default => 70,
);

has '+time_to_build' => (
    default => 60,
);

has '+food_consumption' => (
    default => 25,
);

has '+energy_consumption' => (
    default => 50,
);

has '+ore_consumption' => (
    default => 10,
);

has '+water_consumption' => (
    default => 35,
);

has '+waste_production' => (
    default => 5,
);

has '+happiness_consumption' => (
    default => 10,
);


no Moose;
__PACKAGE__->meta->make_immutable;
