package Lacuna::DB::Result::Map::Body::Asteroid::A11;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Asteroid';

use constant image => 'a11';

use constant magnetite => 9980;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

