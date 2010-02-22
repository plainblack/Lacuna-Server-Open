package Lacuna::DB::Body::Planet::P19;

use Moose;
extends 'Lacuna::DB::Body::Planet';


sub image {
    return 'p19';
}

sub water {
    return 3950;
}

# resource concentrations
sub rutile {
    return 700;
}

sub chromite {
    return 100;
}

sub chalcopyrite {
    return 700;
}

sub galena {
    return 200;
}

sub uraninite {
    return 700;
}

sub bauxite {
    return 300;
}

sub goethite {
    return 700;
}

sub halite {
    return 400;
}

sub gypsum {
    return 700;
}

sub trona {
    return 500;
}

sub sulfur {
    return 700;
}

sub methane {
    return 600;
}

sub kerogen {
    return 1200;
}

sub anthracite {
    return 1100;
}

sub magnetite {
    return 1400;
}

no Moose;
__PACKAGE__->meta->make_immutable;

