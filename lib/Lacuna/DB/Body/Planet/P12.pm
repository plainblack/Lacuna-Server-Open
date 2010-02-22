package Lacuna::DB::Body::Planet::P12;

use Moose;
extends 'Lacuna::DB::Body::Planet';

sub image {
    return 'p12';
}

sub water {
    return 5600;
}


# resource concentrations
sub rutile {
    return 1000;
}

sub chalcopyrite {
    return 1000;
}

sub gold {
    return 1000;
}

sub bauxite {
    return 1000;
}

sub halite {
    return 1000;
}

sub trona {
    return 1000;
}

sub methane {
    return 1000;
}

sub sulfur {
    return 1000;
}

sub monazite {
    return 1000;
}

sub beryl {
    return 1000;
}

no Moose;
__PACKAGE__->meta->make_immutable;

