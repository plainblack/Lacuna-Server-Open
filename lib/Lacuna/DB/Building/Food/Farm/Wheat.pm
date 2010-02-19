package Lacuna::DB::Building::Food::Farm::Wheat;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

sub controller_class {
        return 'Lacuna::Building::Wheat';
}

has '+image' => ( 
    default => 'wheat', 
);

has '+name' => (
    default => 'Wheat Farm',
);

has '+food_to_build' => (
    default => 10,
);

has '+energy_to_build' => (
    default => 100,
);

has '+ore_to_build' => (
    default => 55,
);

has '+water_to_build' => (
    default => 10,
);

has '+waste_to_build' => (
    default => 10,
);

has '+time_to_build' => (
    default => 60,
);

has '+food_consumption' => (
    default => 5,
);

has '+wheat_production' => (
    default => 38,
);

has '+energy_consumption' => (
    default => 1,
);

has '+ore_consumption' => (
    default => 1,
);

has '+water_consumption' => (
    default => 10,
);

has '+waste_production' => (
    default => 28,
);



no Moose;
__PACKAGE__->meta->make_immutable;
