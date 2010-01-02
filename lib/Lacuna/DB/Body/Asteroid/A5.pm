package Lacuna::DB::Body::Asteroid::A5;

use Moose;
extends 'Lacuna::DB::Body::Asteroid';

has '+image' => (
    default => 'a5';
);


no Moose;
__PACKAGE__->meta->make_immutable;

