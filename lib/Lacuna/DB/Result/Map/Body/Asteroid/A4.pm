package Lacuna::DB::Result::Map::Body::Asteroid::A4;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Asteroid';

use constant image => 'a4';

use constant monazite => 9000;

use constant gold => 1000;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

