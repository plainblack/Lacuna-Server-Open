package Lacuna::DB::Body::Planet::P11;

use Moose;
extends 'Lacuna::DB::Body::Planet';

has '+minerals' => (
    default => sub { {
        gold    => 10,
    }},
);

has '+image' => (
    default => 'p11';
);

has '+water' => (
    default => 800;
);


no Moose;
__PACKAGE__->meta->make_immutable;

