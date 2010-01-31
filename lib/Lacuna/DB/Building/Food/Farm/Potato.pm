package Lacuna::DB::Building::Food::Farm::Potato;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

has '+image' => ( 
    default => 'potato', 
);

has '+name' => (
    default => 'Potato Patch',
);

has '+food_produced' (
    default => 'Potatos',
);

has '+food_to_build' => (
    default => -10,
);

has '+energy_to_build' => (
    default => -100,
);

has '+ore_to_build' => (
    default => -55,
);

has '+water_to_build' => (
    default => -10,
);

has '+waste_to_build' => (
    default => 10,
);

has '+time_to_build' => (
    default => 60,
);

has '+food_production' => (
    default => 57,
);

has '+energy_production' => (
    default => -1,
);

has '+ore_production' => (
    default => -2,
);

has '+water_production' => (
    default => -10,
);

has '+waste_production' => (
    default => 8,
);



no Moose;
__PACKAGE__->meta->make_immutable;
