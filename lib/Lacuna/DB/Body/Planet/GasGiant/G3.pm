package Lacuna::DB::Body::Planet::GasGiant::G3;

use Moose;
extends 'Lacuna::DB::Body::Planet::GasGiant';

use constant image => 'pg3';

use constant halite => 7000;

use constant gypsum => 2000;

use constant sulfur => 1000;


no Moose;
__PACKAGE__->meta->make_immutable;

