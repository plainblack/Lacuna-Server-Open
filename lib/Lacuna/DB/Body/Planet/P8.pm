package Lacuna::DB::Body::Planet::P8;

use Moose;
extends 'Lacuna::DB::Body::Planet';

has '+minerals' => (
    default => sub { {
        gold    => 10,
    }},
);

has '+image' => (
    default => 'p8';
);

has '+water' => (
    default => 1100;
);


no Moose;
__PACKAGE__->meta->make_immutable;

