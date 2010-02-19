package Lacuna::DB::Body::Planet::P10;

use Moose;
extends 'Lacuna::DB::Body::Planet';

sub image {
    return 'p10';
}

sub water {
    return 1800;
}

# resource concentrations

sub goethite {
    return 1000;
}

sub gypsum {
    return 500;
}

sub trona {
    return 500;
}

sub kerogen {
    return 500;
}

sub methane {
    return 500;
}

sub anthracite {
    return 500;
}

sub sulfur {
    return 500;
}

sub zircon {
    return 250;
}

sub monazite {
    return 250;
}

sub fluorite {
    return 250;
}

sub beryl {
    return 250;
}

sub magnetite {
    return 5000;
}


no Moose;
__PACKAGE__->meta->make_immutable;

