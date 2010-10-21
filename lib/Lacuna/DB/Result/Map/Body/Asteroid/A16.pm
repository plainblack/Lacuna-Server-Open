package Lacuna::DB::Result::Map::Body::Asteroid::A16;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Asteroid';

use constant image => 'a16';

use constant fluorite => 1793;
use constant gold => 2132;
use constant bauxite => 1894;
use constant trona => 2018;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

