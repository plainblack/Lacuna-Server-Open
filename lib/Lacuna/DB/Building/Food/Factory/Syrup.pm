package Lacuna::DB::Building::Food::Factory::Syrup;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

sub controller_class {
        return 'Lacuna::Building::Syrup';
}

has '+image' => ( 
    default => 'syrup', 
);

has '+name' => (
    default => 'Algae Syrup Bottler',
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

has '+syrup_production' => (
    default => 100,
);

has '+energy_consumption' => (
    default => 75,
);

has '+water_consumption' => (
    default => 25,
);

has '+waste_production' => (
    default => 75,
);



no Moose;
__PACKAGE__->meta->make_immutable;
