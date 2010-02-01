package Lacuna::DB::Building::Water::Reclamation;

use Moose;
extends 'Lacuna::DB::Building::Water';

has '+image' => ( 
    default => 'water-reclamation', 
);

has '+name' => (
    default => 'Water Reclamation Facility',
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
    default => 20,
);

has '+time_to_build' => (
    default => 95,
);

has '+food_production' => (
    default => -5,
);

has '+energy_production' => (
    default => -5,
);

has '+ore_production' => (
    default => -5,
);

has '+water_production' => (
    default => 200,
);

has '+waste_production' => (
    default => -100,
);



no Moose;
__PACKAGE__->meta->make_immutable;
