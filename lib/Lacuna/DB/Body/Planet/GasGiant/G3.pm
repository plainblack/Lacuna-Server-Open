package Lacuna::DB::Body::Planet::GasGiant::G3;

use Moose;
extends 'Lacuna::DB::Body::Planet::GasGiant';

use constant image => 'pg3';

use constant halite => 14000;

use constant gypsum => 4000;

use constant sulfur => 2000;


no Moose;
__PACKAGE__->meta->make_immutable;

