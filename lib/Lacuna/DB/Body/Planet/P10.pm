package Lacuna::DB::Body::Planet::P10;

use Moose;
extends 'Lacuna::DB::Body::Planet';

has '+minerals' => (
    default => sub { {
        gold    => 1800,
    }},
);

has '+image' => (
    default => 'p10',
);

has '+water' => (
    default => 1800,
);


no Moose;
__PACKAGE__->meta->make_immutable;

