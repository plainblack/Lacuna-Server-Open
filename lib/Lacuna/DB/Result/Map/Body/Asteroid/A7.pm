package Lacuna::DB::Result::Map::Body::Asteroid::A7;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Asteroid';

use constant image => 'a7';

use constant uraninite => 2377;
use constant fluorite => 3291;
use constant monazite => 1239;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

