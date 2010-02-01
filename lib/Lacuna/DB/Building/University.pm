package Lacuna::DB::Building::University;

use Moose;
extends 'Lacuna::DB::Building';

has '+image' => ( 
    default => 'university', 
);

has '+name' => (
    default => 'University',
);

has '+food_to_build' => (
    default => -250,
);

has '+energy_to_build' => (
    default => -500,
);

has '+ore_to_build' => (
    default => -500,
);

has '+water_to_build' => (
    default => -100,
);

has '+waste_to_build' => (
    default => 250,
);

has '+time_to_build' => (
    default => 130,
);

has '+food_production' => (
    default => -50,
);

has '+energy_production' => (
    default => -50,
);

has '+ore_production' => (
    default => -10,
);

has '+water_production' => (
    default => -50,
);

has '+waste_production' => (
    default => 50,
);

has '+happiness_production' => (
    default => 50,
);



no Moose;
__PACKAGE__->meta->make_immutable;
