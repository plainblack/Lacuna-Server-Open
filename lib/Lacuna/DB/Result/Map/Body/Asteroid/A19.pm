package Lacuna::DB::Result::Map::Body::Asteroid::A19;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Asteroid';

use constant image => 'a19';

use constant sulfur => 2873;
use constant chalcopyrite => 3333;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

