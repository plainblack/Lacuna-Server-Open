package Lacuna::DB::Body::Asteroid::A1;

use Moose;
extends 'Lacuna::DB::Body::Asteroid';

use constant image => 'a1';

use constant fluorite => 9000;

use constant beryl => 1000;

no Moose;
__PACKAGE__->meta->make_immutable;

