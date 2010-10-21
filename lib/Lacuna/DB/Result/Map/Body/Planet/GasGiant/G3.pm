package Lacuna::DB::Result::Map::Body::Planet::GasGiant::G3;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet::GasGiant';

use constant image => 'pg3';

use constant halite => 14000;

use constant gypsum => 4000;

use constant sulfur => 2000;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

