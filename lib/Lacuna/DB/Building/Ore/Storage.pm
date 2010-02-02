package Lacuna::DB::Building::Ore::Storage;

use Moose;
extends 'Lacuna::DB::Building::Ore';

has '+image' => ( 
    default => 'storage-tanks', 
);

has '+name' => (
    default => 'Storage Tanks',
);

has '+food_to_build' => (
    default => -10,
);

has '+energy_to_build' => (
    default => -10,
);

has '+ore_to_build' => (
    default => -10,
);

has '+water_to_build' => (
    default => -10,
);

has '+waste_to_build' => (
    default => 25,
);

has '+time_to_build' => (
    default => 100,
);


no Moose;
__PACKAGE__->meta->make_immutable;
