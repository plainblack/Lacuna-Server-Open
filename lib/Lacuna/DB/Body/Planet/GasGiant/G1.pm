package Lacuna::DB::Body::Planet::GasGiant::G1;

use Moose;
extends 'Lacuna::DB::Body::Planet::GasGiant';

has '+image' => (
    default => 'pg1.png';
);


no Moose;
__PACKAGE__->meta->make_immutable;

