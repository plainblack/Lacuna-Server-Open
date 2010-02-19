package Lacuna::DB::Building::Food::Factory::Pancake;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

sub controller_class {
        return 'Lacuna::Building::Pancake';
}

has '+image' => ( 
    default => 'pancake', 
);

has '+name' => (
    default => 'Potato Pancake Factory',
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

has '+pancake_production' => (
    default => 90,
);

has '+energy_consumption' => (
    default => 25,
);

has '+water_consumption' => (
    default => 25,
);

has '+waste_production' => (
    default => 25,
);



no Moose;
__PACKAGE__->meta->make_immutable;
