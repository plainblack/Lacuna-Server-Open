package Lacuna::DB::Building::Waste::Treatment;

use Moose;
extends 'Lacuna::DB::Building::Waste';

has '+image' => ( 
    default => 'waste-treatment', 
);

has '+name' => (
    default => 'Waste Treatment Center',
);

has '+food_to_build' => (
    default => 100,
);

has '+energy_to_build' => (
    default => 100,
);

has '+ore_to_build' => (
    default => 100,
);

has '+water_to_build' => (
    default => 100,
);

has '+waste_to_build' => (
    default => 20,
);

has '+time_to_build' => (
    default => 95,
);

has '+food_consumption' => (
    default => 5,
);

has '+energy_consumption' => (
    default => 10,
);

has '+energy_production' => (
    default => 30,
);

has '+ore_consumption' => (
    default => 10,
);

has '+ore_production' => (
    default => 30,
);

has '+water_consumption' => (
    default => 10,
);

has '+water_production' => (
    default => 30,
);

has '+waste_consumption' => (
    default => 110,
);

has '+waste_production' => (
    default => 10,
);



no Moose;
__PACKAGE__->meta->make_immutable;
