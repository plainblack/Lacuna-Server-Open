package Lacuna::DB::Body::Asteroid::A2;

use Moose;
extends 'Lacuna::DB::Body::Asteroid';

use constant image => 'a2';

use constant beryl => 9000;

use constant zircon => 1000;

no Moose;
__PACKAGE__->meta->make_immutable;

