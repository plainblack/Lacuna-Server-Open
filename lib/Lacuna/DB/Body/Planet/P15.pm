package Lacuna::DB::Body::Planet::P15;

use Moose;
extends 'Lacuna::DB::Body::Planet';


sub image {
    return 'p15';
}

sub water {
    return 9018;
}

# resource concentrations
sub rutile {
    return 200;
}

sub chromite {
    return 300;
}

sub chalcopyrite {
    return 100;
}

sub galena {
    return 400;
}

sub uraninite {
    return 250;
}

sub bauxite {
    return 250;
}

sub goethite {
    return 4500;
}

sub halite {
    return 500;
}

sub gypsum {
    return 500;
}

sub trona {
    return 330;
}

sub sulfur {
    return 270;
}

sub methane {
    return 500;
}

sub magnetite {
    return 2000;
}


no Moose;
__PACKAGE__->meta->make_immutable;

