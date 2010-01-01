package Lacuna::DB::Body::Asteroid::A2;

use Moose;
extends 'Lacuna::DB::Body::Asteroid';

has '+image' => (
    default => 'a2.png';
);


no Moose;
__PACKAGE__->meta->make_immutable;

