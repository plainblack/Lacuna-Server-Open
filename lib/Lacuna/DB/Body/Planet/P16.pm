package Lacuna::DB::Body::Planet::P16;

use Moose;
extends 'Lacuna::DB::Body::Planet';

has '+minerals' => (
    default => sub { {
        gold    => 10,
    }},
);

has '+image' => (
    default => 'p16.png';
);

has '+water' => (
    default => 5;
);


no Moose;
__PACKAGE__->meta->make_immutable;

