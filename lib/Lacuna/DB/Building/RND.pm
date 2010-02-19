package Lacuna::DB::Building::RND;

use Moose;
extends 'Lacuna::DB::Building';

sub controller_class {
        return 'Lacuna::Building::RND';
}

has '+image' => ( 
    default => 'rnd', 
);

has '+name' => (
    default => 'Research and Development Lab',
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
    default => 120,
);

has '+food_consumption' => (
    default => 10,
);

has '+energy_consumption' => (
    default => 25,
);

has '+ore_consumption' => (
    default => 25,
);

has '+water_consumption' => (
    default => 10,
);

has '+waste_production' => (
    default => 15,
);

has '+happiness_production' => (
    default => 50,
);



no Moose;
__PACKAGE__->meta->make_immutable;
