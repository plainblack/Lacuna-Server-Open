package Lacuna::DB::Body::Planet::P4;

use Moose;
extends 'Lacuna::DB::Body::Planet';

has '+minerals' => (
    default => sub { {
        gold    => 1410,
    }},
);

has '+image' => (
    default => 'p4';
);

has '+water' => (
    default => 800;
);


no Moose;
__PACKAGE__->meta->make_immutable;

