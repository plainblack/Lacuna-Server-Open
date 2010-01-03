package Lacuna::DB::Body::Planet::P18;

use Moose;
extends 'Lacuna::DB::Body::Planet';

has '+minerals' => (
    default => sub { {
        gold    => 10,
    }},
);

has '+image' => (
    default => 'p18',
);

has '+water' => (
    default => 7600,
);


no Moose;
__PACKAGE__->meta->make_immutable;

