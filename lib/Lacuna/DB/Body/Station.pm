package Lacuna::DB::Result::Body::Station;

use Moose;
extends 'Lacuna::DB::Result::Body';

use constant image => 'station';


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

