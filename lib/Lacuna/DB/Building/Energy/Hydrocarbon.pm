package Lacuna::DB::Building::Energy::Hydrocarbon;

use Moose;
extends 'Lacuna::DB::Building::Energy';

has '+image' => ( 
    default => 'hydrocarbon', 
);

has '+name' => (
    default => 'Hydrocarbon Energy Plant',
);

has '+food_to_build' => (
    default => -100,
);

has '+energy_to_build' => (
    default => -10,
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
    default => 70,
);

has '+food_production' => (
    default => -15,
);

has '+energy_production' => (
    default => 370,
);

has '+ore_production' => (
    default => -90,
);

has '+water_production' => (
    default => -15,
);

has '+waste_production' => (
    default => 230,
);



no Moose;
__PACKAGE__->meta->make_immutable;
