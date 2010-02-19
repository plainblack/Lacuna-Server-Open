package Lacuna::DB::Building::Permanent::Crater;

use Moose;
extends 'Lacuna::DB::Building::Permanent';

sub controller_class {
        return 'Lacuna::Building::Crater';
}

sub image {
    return 'crater';
}

sub name {
    return 'Crater';
}


no Moose;
__PACKAGE__->meta->make_immutable;
