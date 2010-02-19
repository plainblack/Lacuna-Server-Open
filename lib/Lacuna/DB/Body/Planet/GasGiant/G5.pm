package Lacuna::DB::Body::Planet::GasGiant::G5;

use Moose;
extends 'Lacuna::DB::Body::Planet::GasGiant';

sub image {
    return 'pg5';
}

sub goethite {
    return 7000;
}

sub sulfur {
    return 2000;
}

sub magnetite {
    return 1000;
}


no Moose;
__PACKAGE__->meta->make_immutable;

