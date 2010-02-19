package Lacuna::DB::Body::Station;

use Moose;
extends 'Lacuna::DB::Body';

sub image {
    return 'station';
}


no Moose;
__PACKAGE__->meta->make_immutable;

