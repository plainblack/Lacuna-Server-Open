package Lacuna::DB::Body::Planet::P19;

use Moose;
extends 'Lacuna::DB::Body::Planet';

has '+minerals' => (
    default => sub { {
        gold    => 10,
    }},
);

has '+image' => (
    default => 'p19';
);

has '+water' => (
    default => 3950;
);


no Moose;
__PACKAGE__->meta->make_immutable;

