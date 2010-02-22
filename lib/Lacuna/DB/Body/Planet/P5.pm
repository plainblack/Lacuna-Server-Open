package Lacuna::DB::Body::Planet::P5;

use Moose;
extends 'Lacuna::DB::Body::Planet';

sub image {
    return 'p5';
}

sub water {
    return 1200;
}

# resource concentrations
sub rutile {
    return 1250;
}

sub chalcopyrite {
    return 250;
}

sub galena {
    return 2250;
}

sub uraninite {
    return 250;
}

sub bauxite {
    return 2250;
}

sub goethite {
    return 1250;
}

sub halite {
    return 250;
}

sub gypsum {
    return 1250;
}

sub trona {
    return 250;
}

sub sulfur {
    return 250;
}

sub methane {
    return 250;
}

sub magnetite {
    return 250;
}


no Moose;
__PACKAGE__->meta->make_immutable;

