package Lacuna::DB::Result::Map::Body::Asteroid::A21;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Asteroid';

use constant image => 'debris1';

use constant magnetite => 10;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

