package Lacuna::DB::Body::Asteroid::A1;

use Moose;
extends 'Lacuna::DB::Body::Asteroid';

has '+image' => (
    default => 'a1.png';
);


no Moose;
__PACKAGE__->meta->make_immutable;

