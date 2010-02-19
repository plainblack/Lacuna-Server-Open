package Lacuna::DB::Building::Food::Farm::Beeldeban;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

sub controller_class {
        return 'Lacuna::Building::Beeldeban';
}

has '+image' => ( 
    default => 'beeldeban', 
);

has '+name' => (
    default => 'Beeldeban Herder',
);

has '+food_to_build' => (
    default => 100,
);

has '+energy_to_build' => (
    default => 100,
);

has '+ore_to_build' => (
    default => 125,
);

has '+water_to_build' => (
    default => 50,
);

has '+waste_to_build' => (
    default => 35,
);

has '+time_to_build' => (
    default => 80,
);

has '+food_consumption' => (
    default => 5,
);

has '+beetle_production' => (
    default => 35,
);

has '+energy_consumption' => (
    default => 2,
);

has '+ore_consumption' => (
    default => 4,
);

has '+water_consumption' => (
    default => 3,
);

has '+waste_production' => (
    default => 23,
);

has '+waste_consumption' => (
    default => 15,
);



no Moose;
__PACKAGE__->meta->make_immutable;
