package Lacuna::DB::Building::Permanent::RockyOutcrop;

use Moose;
extends 'Lacuna::DB::Building::Permanent';

sub controller_class {
        return 'Lacuna::Building::RockyOutcrop';
}

sub image {
    return 'rocky-outcrop';
}

sub name {
    return 'Rocky Outcropping';
}


no Moose;
__PACKAGE__->meta->make_immutable;
