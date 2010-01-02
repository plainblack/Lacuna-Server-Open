package Lacuna::DB::Body::Planet::P14;

use Moose;
extends 'Lacuna::DB::Body::Planet';

has '+minerals' => (
    default => sub { {
        gold    => 10,
    }},
);

has '+image' => (
    default => 'p14';
);

has '+water' => (
    default => 1410;
);


no Moose;
__PACKAGE__->meta->make_immutable;

