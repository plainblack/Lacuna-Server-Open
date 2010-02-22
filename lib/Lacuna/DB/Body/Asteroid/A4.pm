package Lacuna::DB::Body::Asteroid::A4;

use Moose;
extends 'Lacuna::DB::Body::Asteroid';

sub image {
    return 'a4';
}

sub monazite {
    return 9000;
}

sub gold {
    return 1000;
}

no Moose;
__PACKAGE__->meta->make_immutable;

