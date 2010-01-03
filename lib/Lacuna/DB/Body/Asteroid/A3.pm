package Lacuna::DB::Body::Asteroid::A3;

use Moose;
extends 'Lacuna::DB::Body::Asteroid';

has '+image' => (
    default => 'a3',
);


no Moose;
__PACKAGE__->meta->make_immutable;

