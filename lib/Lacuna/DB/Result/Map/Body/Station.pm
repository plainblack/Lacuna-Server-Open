package Lacuna::DB::Result::Map::Body::Station;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body';

use constant image => 'station';


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

