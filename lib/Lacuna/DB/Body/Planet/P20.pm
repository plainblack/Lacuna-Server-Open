package Lacuna::DB::Body::Planet::P20;

use Moose;
extends 'Lacuna::DB::Body::Planet';

has '+minerals' => (
    default => sub { {
        gold    => 10,
    }},
);

has '+image' => (
    default => 'p20';
);

has '+water' => (
    default => 2608;
);


no Moose;
__PACKAGE__->meta->make_immutable;

