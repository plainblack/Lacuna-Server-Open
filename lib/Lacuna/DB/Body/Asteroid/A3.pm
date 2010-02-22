package Lacuna::DB::Body::Asteroid::A3;

use Moose;
extends 'Lacuna::DB::Body::Asteroid';

sub image {
    return 'a3';
}

sub zircon {
    return 9000;
}

sub monazite {
    return 1000;
}

no Moose;
__PACKAGE__->meta->make_immutable;

