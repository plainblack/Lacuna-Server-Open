package Lacuna::DB::Building::Energy::Fission;

use Moose;
extends 'Lacuna::DB::Building::Energy';

has '+image' => ( 
    default => 'fission', 
);

has '+name' => (
    default => 'Fission Energy Plant',
);

has '+food_to_build' => (
    default => -100,
);

has '+energy_to_build' => (
    default => -200,
);

has '+ore_to_build' => (
    default => -200,
);

has '+water_to_build' => (
    default => -150,
);

has '+waste_to_build' => (
    default => 75,
);

has '+time_to_build' => (
    default => 155,
);

has '+food_production' => (
    default => -5,
);

has '+energy_production' => (
    default => 380,
);

has '+ore_production' => (
    default => -35,
);

has '+water_production' => (
    default => -50,
);

has '+waste_production' => (
    default => 70,
);



no Moose;
__PACKAGE__->meta->make_immutable;
