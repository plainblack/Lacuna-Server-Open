package Lacuna::DB::Body::Asteroid::A5;

use Moose;
extends 'Lacuna::DB::Body::Asteroid';

sub image {
    return 'a5';
}

sub fluorite {
    return 1000;
}

sub gold {
    return 9000;
}

no Moose;
__PACKAGE__->meta->make_immutable;

