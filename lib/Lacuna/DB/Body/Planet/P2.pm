package Lacuna::DB::Body::Planet::P2;

use Moose;
extends 'Lacuna::DB::Body::Planet';

has '+minerals' => (
    default => sub { {
        gold    => 10,
    }},
);

has '+image' => (
    default => 'p2.png';
);

has '+water' => (
    default => 5;
);


no Moose;
__PACKAGE__->meta->make_immutable;

