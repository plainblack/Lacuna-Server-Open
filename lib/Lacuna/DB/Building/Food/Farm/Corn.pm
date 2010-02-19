package Lacuna::DB::Building::Food::Farm::Corn;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

sub controller_class {
        return 'Lacuna::Building::Corn';
}

has '+image' => ( 
    default => 'corn', 
);

has '+name' => (
    default => 'Corn Plantation',
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

has '+corn_production' => (
    default => 44,
);

has '+energy_consumption' => (
    default => 1,
);

has '+ore_consumption' => (
    default => 11,
);

has '+water_consumption' => (
    default => -10,
);

has '+waste_production' => (
    default => 22,
);



no Moose;
__PACKAGE__->meta->make_immutable;
