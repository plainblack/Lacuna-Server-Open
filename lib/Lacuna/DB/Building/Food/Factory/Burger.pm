package Lacuna::DB::Building::Food::Factory::Burger;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

sub controller_class {
        return 'Lacuna::Building::Burger';
}

has '+image' => ( 
    default => 'burger', 
);

has '+name' => (
    default => 'Malcud Burger Packer',
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

has '+burger_production' => (
    default => 100,
);

has '+energy_consumption' => (
    default => 40,
);

has '+ore_consumption' => (
    default => 1,
);

has '+water_consumption' => (
    default => 10,
);

has '+waste_production' => (
    default => 25,
);



no Moose;
__PACKAGE__->meta->make_immutable;
