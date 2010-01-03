package Lacuna::DB::Body::Planet::P12;

use Moose;
extends 'Lacuna::DB::Body::Planet';

has '+minerals' => (
    default => sub { {
        gold    => 12,
    }},
);

has '+image' => (
    default => 'p12',
);

has '+water' => (
    default => 5600,
);


no Moose;
__PACKAGE__->meta->make_immutable;

