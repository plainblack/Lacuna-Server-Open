package Lacuna::DB::Building::Permanent::Lake;

use Moose;
extends 'Lacuna::DB::Building::Permanent';

sub controller_class {
        return 'Lacuna::Building::Lake';
}

sub check_build_prereqs {
    confess [1013,"You can't build a lake. It forms naturally."];
}

sub image {
    return 'lake';
}

sub name {
    return 'Lake';
}


no Moose;
__PACKAGE__->meta->make_immutable;
