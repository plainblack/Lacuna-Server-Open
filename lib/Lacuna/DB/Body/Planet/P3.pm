package Lacuna::DB::Body::Planet::P3;

use Moose;
extends 'Lacuna::DB::Body::Planet';

has '+minerals' => (
    default => sub { {
        gold    => 10,
    }},
);

has '+image' => (
    default => 'p3';
);

has '+water' => (
    default => 555;
);


no Moose;
__PACKAGE__->meta->make_immutable;

