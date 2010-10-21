package Lacuna::DB::Result::Map::Body::Asteroid::A2;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Asteroid';

use constant image => 'a2';

use constant beryl => 4000;

use constant zircon => 1000;

use constant chalcopyrite => 5000;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

