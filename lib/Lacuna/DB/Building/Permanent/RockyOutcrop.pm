package Lacuna::DB::Building::Permanent::RockyOutcrop;

use Moose;
extends 'Lacuna::DB::Building::Permanent';

has '+image' => ( 
    default => 'rocky-outcrop', 
);

has '+name' => (
    default => 'Rocky Outcropping',
);


no Moose;
__PACKAGE__->meta->make_immutable;
