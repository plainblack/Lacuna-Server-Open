package Lacuna::DB::Result::Map::Body::Asteroid::A9;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Asteroid';

use constant image => 'a9';

use constant methane => 5500;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

