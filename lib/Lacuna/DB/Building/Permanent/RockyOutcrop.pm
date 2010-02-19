package Lacuna::DB::Building::Permanent::RockyOutcrop;

use Moose;
extends 'Lacuna::DB::Building::Permanent';

sub controller_class {
        return 'Lacuna::Building::RockyOutcrop';
}

has '+image' => ( 
    default => 'rocky-outcrop', 
);

has '+name' => (
    default => 'Rocky Outcropping',
);


no Moose;
__PACKAGE__->meta->make_immutable;
