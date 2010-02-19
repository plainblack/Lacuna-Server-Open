package Lacuna::DB::Body::Planet::P1;

use Moose;
extends 'Lacuna::DB::Body::Planet';

sub image {
    return 'p1';
}

sub water {
    return 1700;
}

# resource concentrations
sub rutile {
    return 500;
}

sub chromite {
    return 5000;
}

sub chalcopyrite {
    return 1000;
}

sub galena {
    return 1500;
}

sub gold {
    return 500;
}

sub uraninite {
    return 250;
}

sub bauxite {
    return 250;
}

sub goethite {
    return 500;
}

sub halite {
    return 250;
}

sub gypsum {
    return 250;
}


no Moose;
__PACKAGE__->meta->make_immutable;

