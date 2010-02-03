package Lacuna::DB::Building::Permanent::Lake;

use Moose;
extends 'Lacuna::DB::Building::Permanent';

has '+image' => ( 
    default => 'lake', 
);

has '+name' => (
    default => 'Lake',
);


no Moose;
__PACKAGE__->meta->make_immutable;
