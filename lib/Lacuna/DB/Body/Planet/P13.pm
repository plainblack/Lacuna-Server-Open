package Lacuna::DB::Body::Planet::P13;

use Moose;
extends 'Lacuna::DB::Body::Planet';

has '+minerals' => (
    default => sub { {
        gold    => 10,
    }},
);

has '+image' => (
    default => 'p13',
);

has '+water' => (
    default => 3800,
);


no Moose;
__PACKAGE__->meta->make_immutable;

