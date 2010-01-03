package Lacuna::DB::Body::Planet::P15;

use Moose;
extends 'Lacuna::DB::Body::Planet';

has '+minerals' => (
    default => sub { {
        gold    => 10,
    }},
);

has '+image' => (
    default => 'p15',
);

has '+water' => (
    default => 9018,
);


no Moose;
__PACKAGE__->meta->make_immutable;

