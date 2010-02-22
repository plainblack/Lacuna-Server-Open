package Lacuna::DB::Body::Planet::GasGiant::G3;

use Moose;
extends 'Lacuna::DB::Body::Planet::GasGiant';

sub image {
    return 'pg3';
}

sub halite {
    return 7000;
}

sub gypsum {
    return 2000;
}

sub sulfur {
    return 1000;
}


no Moose;
__PACKAGE__->meta->make_immutable;

