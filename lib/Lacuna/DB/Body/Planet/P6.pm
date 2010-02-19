package Lacuna::DB::Body::Planet::P6;

use Moose;
extends 'Lacuna::DB::Body::Planet';

sub image {
    return 'p6';
}

sub water {
    return 2905;
}

# resource concentrations

sub goethite {
    return 1400;
}

sub halite {
    return 1000;
}

sub gypsum {
    return 1500;
}

sub trona {
    return 1300;
}

sub sulfur {
    return 1700;
}

sub methane {
    return 1200;
}

sub magnetite {
    return 1900;
}


no Moose;
__PACKAGE__->meta->make_immutable;

