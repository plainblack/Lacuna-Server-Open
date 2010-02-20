package Lacuna::DB::Building::Permanent::Crater;

use Moose;
extends 'Lacuna::DB::Building::Permanent';

sub controller_class {
        return 'Lacuna::Building::Crater';
}

sub check_build_prereqs {
    confess [1013,"You can't build a crater. It forms naturally."];
}

sub image {
    return 'crater';
}

sub name {
    return 'Crater';
}


no Moose;
__PACKAGE__->meta->make_immutable;
