package Lacuna::DB::Body::Planet::GasGiant::G2;

use Moose;
extends 'Lacuna::DB::Body::Planet::GasGiant';

has '+image' => (
    default => 'pg2',
);

has '+minerals' => (
    default => sub { {
        gold    => 10,
    }},
);


no Moose;
__PACKAGE__->meta->make_immutable;

