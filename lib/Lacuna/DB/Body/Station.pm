package Lacuna::DB::Body::Station;

use Moose;
extends 'Lacuna::DB::Body';

use constant image => 'station';


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

