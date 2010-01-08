package Lacuna::DB::Building::Factory::Syrup;

use Moose;
extends 'Lacuna::DB::Building::Factory';

has '+food_produced' => ( 
    default => 'Syrup',
);

has '+image' => ( 
    default => 'syrup0',
);

has '+converts_food' = (
    default => 'Algae',
);


no Moose;
__PACKAGE__->meta->make_immutable;
