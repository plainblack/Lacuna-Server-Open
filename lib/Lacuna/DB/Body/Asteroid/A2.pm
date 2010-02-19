package Lacuna::DB::Body::Asteroid::A2;

use Moose;
extends 'Lacuna::DB::Body::Asteroid';

sub image {
    return 'a2';
}

sub beryl {
    return 9000;
}

sub zircon {
    return 1000;
}

no Moose;
__PACKAGE__->meta->make_immutable;

