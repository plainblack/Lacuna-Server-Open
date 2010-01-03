package Lacuna::DB::Body::Planet::P17;

use Moose;
extends 'Lacuna::DB::Body::Planet';

has '+minerals' => (
    default => sub { {
        gold    => 10,
    }},
);

has '+image' => (
    default => 'p17',
);

has '+water' => (
    default => 10000,
);


no Moose;
__PACKAGE__->meta->make_immutable;

