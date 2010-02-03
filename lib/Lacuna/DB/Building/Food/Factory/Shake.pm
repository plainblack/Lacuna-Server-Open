package Lacuna::DB::Building::Food::Factory::Shake;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

has '+image' => ( 
    default => 'shake', 
);

has '+name' => (
    default => 'Beeldeban Protein Shake Factory',
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

has '+shake_production' => (
    default => 100,
);

has '+energy_consumption' => (
    default => 25,
);

has '+ore_consumption' => (
    default => 5,
);

has '+water_consumption' => (
    default => 40,
);

has '+waste_production' => (
    default => 20,
);



no Moose;
__PACKAGE__->meta->make_immutable;
