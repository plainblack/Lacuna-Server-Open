package Lacuna::DB::Body::Planet::GasGiant::G3;

use Moose;
extends 'Lacuna::DB::Body::Planet::GasGiant';

has '+image' => (
    default => 'pg3';
);

has '+minerals' => (
    default => sub { {
        gold    => 10,
    }},
);


no Moose;
__PACKAGE__->meta->make_immutable;

