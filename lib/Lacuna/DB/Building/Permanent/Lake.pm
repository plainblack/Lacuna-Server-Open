package Lacuna::DB::Building::Permanent::Lake;

use Moose;
extends 'Lacuna::DB::Building::Permanent';

sub controller_class {
        return 'Lacuna::Building::Lake';
}

sub image {
    return 'lake';
}

sub name {
    return 'Lake';
}


no Moose;
__PACKAGE__->meta->make_immutable;
