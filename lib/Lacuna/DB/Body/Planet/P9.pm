package Lacuna::DB::Body::Planet::P9;

use Moose;
extends 'Lacuna::DB::Body::Planet';

has '+minerals' => (
    default => sub { {
        gold    => 10,
    }},
);

has '+image' => (
    default => 'p9';
);

has '+water' => (
    default => 2304;
);


no Moose;
__PACKAGE__->meta->make_immutable;

