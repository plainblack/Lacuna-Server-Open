package Lacuna::DB::Body::Planet::P16;

use Moose;
extends 'Lacuna::DB::Body::Planet';

has '+minerals' => (
    default => sub { {
        gold    => 10,
    }},
);

has '+image' => (
    default => 'p16',
);

has '+water' => (
    default => 1000,
);


no Moose;
__PACKAGE__->meta->make_immutable;

