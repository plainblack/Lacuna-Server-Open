package Lacuna::DB::Body::Planet::P17;

use Moose;
extends 'Lacuna::DB::Body::Planet';

has '+minerals' => (
    default => sub { {
        gold    => 10,
    }},
);

has '+image' => (
    default => 'p17.png';
);

has '+water' => (
    default => 5;
);


no Moose;
__PACKAGE__->meta->make_immutable;

