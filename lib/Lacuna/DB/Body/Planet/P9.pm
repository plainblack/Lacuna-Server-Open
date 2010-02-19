package Lacuna::DB::Body::Planet::P9;

use Moose;
extends 'Lacuna::DB::Body::Planet';

sub image {
    return 'p9';
}

sub water {
    return 2304;
}

# resource concentrations
sub rutile {
    return 800;
}

sub chromite {
    return 900;
}

sub chalcopyrite {
    return 100;
}

sub galena {
    return 200;
}

sub uraninite {
    return 400;
}

sub bauxite {
    return 300;
}

sub goethite {
    return 200;
}

sub halite {
    return 500;
}

sub gypsum {
    return 600;
}

sub trona {
    return 700;
}

sub sulfur {
    return 1600;
}

sub methane {
    return 1700;
}

sub kerogen {
    return 1800;
}

sub anthracite {
    return 100;
}

sub magnetite {
    return 100;
}


no Moose;
__PACKAGE__->meta->make_immutable;

