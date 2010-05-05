package Lacuna::DB::Result::Body::Asteroid::A5;

use Moose;
extends 'Lacuna::DB::Result::Body::Asteroid';

use constant image => 'a5';

use constant fluorite => 1000;

use constant gold => 9000;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

