package Lacuna::DB::Result::Map::Body::Asteroid::A13;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Asteroid';

use constant image => 'a13';

use constant zircon => 2590;
use constant trona => 6574;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

