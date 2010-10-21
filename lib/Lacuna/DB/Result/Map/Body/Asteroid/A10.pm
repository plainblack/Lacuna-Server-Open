package Lacuna::DB::Result::Map::Body::Asteroid::A10;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Asteroid';

use constant image => 'a10';

use constant anthracite => 6250;
use constant trona => 300;
use constant halite => 55;
use constant bauxite => 108;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

