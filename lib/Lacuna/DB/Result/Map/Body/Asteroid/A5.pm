package Lacuna::DB::Result::Map::Body::Asteroid::A5;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Asteroid';

use constant image => 'a5';

use constant fluorite => 1000;

use constant gold => 9000;

use constant water => 500;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

