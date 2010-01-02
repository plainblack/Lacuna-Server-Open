package Lacuna::DB::Body::Planet::GasGiant::G5;

use Moose;
extends 'Lacuna::DB::Body::Planet::GasGiant';

has '+image' => (
    default => 'pg5';
);

has '+minerals' => (
    default => sub { {
        gold    => 10,
    }},
);


no Moose;
__PACKAGE__->meta->make_immutable;

