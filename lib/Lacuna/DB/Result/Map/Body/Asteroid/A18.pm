package Lacuna::DB::Result::Map::Body::Asteroid::A18;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Asteroid';

use constant image => 'a18';

use constant trona => 3326;
use constant gypsum => 4120;
use constant water => 115;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

