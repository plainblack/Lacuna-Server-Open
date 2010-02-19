package Lacuna::DB::Body::Asteroid::A1;

use Moose;
extends 'Lacuna::DB::Body::Asteroid';

sub image {
    return 'a1';
}

sub fluorite {
    return 9000;
}

sub beryl {
    return 1000;
}

no Moose;
__PACKAGE__->meta->make_immutable;

