package Lacuna::DB::Body::Planet::P3;

use Moose;
extends 'Lacuna::DB::Body::Planet';


sub image {
    return 'p3';
}

sub water {
    return 555;
}

# resource concentrations

sub uraninite {
    return 3000;
}

sub methane {
    return 2900;
}

sub kerogen {
    return 1400;
}

sub anthracite {
    return 2700;
}

no Moose;
__PACKAGE__->meta->make_immutable;

