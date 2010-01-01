package Lacuna::DB::Body::Station;

use Moose;
extends 'Lacuna::DB::Body';

has '+image' => (
    default => 'station.png';
);


no Moose;
__PACKAGE__->meta->make_immutable;

