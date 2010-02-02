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

has '+food_consumption' => (
    default => 5,
);

has '+energy_consumption' => (
    default => 70,
);

has '+energy_production' => (
    default => 450,
);

has '+ore_consumption' => (
    default => 35,
);

has '+water_consumption' => (
    default => 50,
);

has '+waste_production' => (
    default => 70,
);



no Moose;
__PACKAGE__->meta->make_immutable;
