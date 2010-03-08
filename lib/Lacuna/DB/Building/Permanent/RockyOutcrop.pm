package Lacuna::DB::Building::Permanent::RockyOutcrop;

use Moose;
extends 'Lacuna::DB::Building::Permanent';

sub controller_class {
        return 'Lacuna::Building::RockyOutcrop';
}

sub check_build_prereqs {
    confess [1013,"You can't build a rocky outcropping. It forms naturally."];
}

sub image {
    return 'rockyoutcrop';
}

sub name {
    return 'Rocky Outcropping';
}


no Moose;
__PACKAGE__->meta->make_immutable;
