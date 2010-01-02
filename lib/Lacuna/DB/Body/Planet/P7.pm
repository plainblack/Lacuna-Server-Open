package Lacuna::DB::Body::Planet::P7;

use Moose;
extends 'Lacuna::DB::Body::Planet';

has '+minerals' => (
    default => sub { {
        gold    => 10,
    }},
);

has '+image' => (
    default => 'p7';
);

has '+water' => (
    default => 4700;
);


no Moose;
__PACKAGE__->meta->make_immutable;

