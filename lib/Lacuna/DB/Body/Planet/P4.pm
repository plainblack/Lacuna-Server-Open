package Lacuna::DB::Body::Planet::P4;

use Moose;
extends 'Lacuna::DB::Body::Planet';

sub image {
    return 'p4';
}

sub water {
    return 800;
}

# resource concentrations

sub chalcopyrite {
    return 1000;
}

sub uraninite {
    return 1500;
}

sub goethite {
    return 1500;
}

sub gypsum {
    return 1500;
}

sub sulfur {
    return 1500;
}

sub kerogen {
    return 1500;
}

sub magnetite {
    return 1500;
}


no Moose;
__PACKAGE__->meta->make_immutable;

