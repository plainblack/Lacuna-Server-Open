package Lacuna::DB::Body::Planet::GasGiant::G5;

use Moose;
extends 'Lacuna::DB::Body::Planet::GasGiant';

use constant image => 'pg5';

use constant goethite => 14000;

use constant sulfur => 4000;

use constant magnetite => 2000;


no Moose;
__PACKAGE__->meta->make_immutable;

