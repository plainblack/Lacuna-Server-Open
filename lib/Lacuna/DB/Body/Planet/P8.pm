package Lacuna::DB::Body::Planet::P8;

use Moose;
extends 'Lacuna::DB::Body::Planet';

sub image {
    return 'p8';
}

sub water {
    return 1100;
}

# resource concentrations

sub halite {
    return 1300;
}

sub gypsum {
    return 1250;
}

sub trona {
    return 1250;
}

sub sulfur {
    return 1;
}

sub methane {
    return 1;
}

sub kerogen {
    return 3100;
}

sub anthracite {
    return 3100;
}

no Moose;
__PACKAGE__->meta->make_immutable;

