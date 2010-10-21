package Lacuna::DB::Result::Map::Body::Asteroid::A14;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Asteroid';

use constant image => 'a14';

use constant gypsum => 2897;
use constant galena => 3038;
use constant goethite => 2895;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

