package Lacuna::DB::Building::Park;

use Moose;
extends 'Lacuna::DB::Building';

has '+image' => ( 
    default => 'park', 
);

has '+name' => (
    default => 'Park',
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
    default => 100,
);

has '+time_to_build' => (
    default => 100,
);

has '+food_consumption' => (
    default => 10,
);

has '+energy_consumption' => (
    default => 10,
);

has '+ore_consumption' => (
    default => 20,
);

has '+water_consumption' => (
    default => 60,
);

has '+waste_production' => (
    default => 75,
);

has '+happiness_production' => (
    default => 75,
);



no Moose;
__PACKAGE__->meta->make_immutable;
