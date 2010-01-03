package Lacuna::DB::Body::Station;

use Moose;
extends 'Lacuna::DB::Body';

has '+image' => (
    default => 'station',
);


no Moose;
__PACKAGE__->meta->make_immutable;

