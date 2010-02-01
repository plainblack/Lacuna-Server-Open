package Lacuna::DB::Building::EntertainmentDistrict;

use Moose;
extends 'Lacuna::DB::Building';

has '+image' => ( 
    default => 'entertainment', 
);

has '+name' => (
    default => 'Entertainment District',
);

has '+food_to_build' => (
    default => -500,
);

has '+energy_to_build' => (
    default => -500,
);

has '+ore_to_build' => (
    default => -800,
);

has '+water_to_build' => (
    default => -500,
);

has '+waste_to_build' => (
    default => 500,
);

has '+time_to_build' => (
    default => 250,
);

has '+food_production' => (
    default => -100,
);

has '+energy_production' => (
    default => -100,
);

has '+ore_production' => (
    default => -10,
);

has '+water_production' => (
    default => -100,
);

has '+waste_production' => (
    default => 300,
);

has '+happiness_production' => (
    default => 200,
);



no Moose;
__PACKAGE__->meta->make_immutable;
