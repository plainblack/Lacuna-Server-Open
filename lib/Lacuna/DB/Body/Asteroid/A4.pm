package Lacuna::DB::Body::Asteroid::A4;

use Moose;
extends 'Lacuna::DB::Body::Asteroid';

use constant image => 'a4';

use constant monazite => 9000;

use constant gold => 1000;

no Moose;
__PACKAGE__->meta->make_immutable;

