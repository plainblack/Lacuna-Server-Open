package Lacuna::DB::Body::Planet::P2;

use Moose;
extends 'Lacuna::DB::Body::Planet';


sub image {
    return 'p2';
}

sub water {
    return 1900;
}

# resource concentrations

sub gypsum {
    return 1500;
}

sub trona {
    return 1500;
}

sub sulfur {
    return 2300;
}

sub methane {
    return 2700;
}

sub magnetite {
    return 1000;
}

sub fluorite {
    return 190;
}

sub beryl {
    return 310;
}

sub zircon {
    return 120;
}

sub monazite {
    return 130;
}

sub gold {
    return 250;
}


no Moose;
__PACKAGE__->meta->make_immutable;

