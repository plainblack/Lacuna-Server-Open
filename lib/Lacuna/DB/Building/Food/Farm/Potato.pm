package Lacuna::DB::Building::Food::Farm::Potato;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

sub controller_class {
        return 'Lacuna::Building::Potato';
}

has '+image' => ( 
    default => 'potato', 
);

has '+name' => (
    default => 'Potato Patch',
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

has '+potato_production' => (
    default => 62,
);

has '+energy_consumption' => (
    default => 1,
);

has '+ore_consumption' => (
    default => 2,
);

has '+water_consumption' => (
    default => 10,
);

has '+waste_production' => (
    default => 8,
);



no Moose;
__PACKAGE__->meta->make_immutable;
