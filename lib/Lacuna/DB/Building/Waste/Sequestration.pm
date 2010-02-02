package Lacuna::DB::Building::Waste::Sequestration;

use Moose;
extends 'Lacuna::DB::Building::Waste';

has '+image' => ( 
    default => 'sequestration', 
);

has '+name' => (
    default => 'Waste Sequestration Well',
);

has '+food_to_build' => (
    default => -10,
);

has '+energy_to_build' => (
    default => -10,
);

has '+ore_to_build' => (
    default => -10,
);

has '+water_to_build' => (
    default => -10,
);

has '+waste_to_build' => (
    default => 25,
);

has '+time_to_build' => (
    default => 100,
);

has '+waste_storage' => (
    default => 1500,
);



no Moose;
__PACKAGE__->meta->make_immutable;
