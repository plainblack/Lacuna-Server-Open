package Lacuna::DB::Building::Food::Farm::Dairy;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

sub controller_class {
        return 'Lacuna::Building::Dairy';
}

has '+image' => ( 
    default => 'dairy', 
);

has '+name' => (
    default => 'Dairy Farm',
);

has '+food_to_build' => (
    default => 200,
);

has '+energy_to_build' => (
    default => 100,
);

has '+ore_to_build' => (
    default => 150,
);

has '+water_to_build' => (
    default => 60,
);

has '+waste_to_build' => (
    default => 50,
);

has '+time_to_build' => (
    default => 80,
);

has '+food_consumption' => (
    default => 5,
);

has '+milk_production' => (
    default => 47,
);

has '+energy_consumption' => (
    default => 8,
);

has '+ore_consumption' => (
    default => 3,
);

has '+water_consumption' => (
    default => 15,
);

has '+waste_production' => (
    default => 48,
);



no Moose;
__PACKAGE__->meta->make_immutable;
