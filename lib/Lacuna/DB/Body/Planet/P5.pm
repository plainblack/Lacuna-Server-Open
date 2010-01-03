package Lacuna::DB::Body::Planet::P5;

use Moose;
extends 'Lacuna::DB::Body::Planet';

has '+minerals' => (
    default => sub { {
        gold    => 10,
    }},
);

has '+image' => (
    default => 'p5',
);

has '+water' => (
    default => 1200,
);


no Moose;
__PACKAGE__->meta->make_immutable;

