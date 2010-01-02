package Lacuna::DB::Body::Asteroid::A4;

use Moose;
extends 'Lacuna::DB::Body::Asteroid';

has '+image' => (
    default => 'a4';
);


no Moose;
__PACKAGE__->meta->make_immutable;

