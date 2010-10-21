package Lacuna::DB::Result::Map::Body::Asteroid::A1;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Asteroid';

use constant image => 'a1';

use constant fluorite => 9000;

use constant beryl => 1000;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

