package Lacuna::DB::Building::Food::Factory::Cider;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

has '+image' => ( 
    default => 'cider', 
);

has '+name' => (
    default => 'Apple Cider Bottler',
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
    default => 100,
);

has '+time_to_build' => (
    default => 200,
);

has '+food_consumption' => (
    default => 150,
);

has '+cider_consumption' => (
    default => 75,
);

has '+energy_consumption' => (
    default => 50,
);

has '+water_consumption' => (
    default => 50,
);

has '+waste_production' => (
    default => 100,
);



no Moose;
__PACKAGE__->meta->make_immutable;
