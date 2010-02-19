package Lacuna::DB::Body::Planet::P14;

use Moose;
extends 'Lacuna::DB::Body::Planet';


sub image {
    return 'p14';
}

sub water {
    return 1410;
}

# resource concentrations
sub rutile {
    return 100;
}

sub chromite {
    return 100;
}

sub chalcopyrite {
    return 100;
}

sub galena {
    return 100;
}

sub uraninite {
    return 100;
}

sub bauxite {
    return 100;
}

sub goethite {
    return 100;
}

sub halite {
    return 100;
}

sub gypsum {
    return 100;
}

sub trona {
    return 4000;
}

sub sulfur {
    return 2300;
}

sub methane {
    return 2700;
}

sub magnetite {
    return 100;
}


no Moose;
__PACKAGE__->meta->make_immutable;

