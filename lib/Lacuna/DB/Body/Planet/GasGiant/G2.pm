package Lacuna::DB::Body::Planet::GasGiant::G2;

use Moose;
extends 'Lacuna::DB::Body::Planet::GasGiant';

use constant image => 'pg2';



use constant galena => 7000;

use constant bauxite => 2000;

use constant goethite => 1000;


no Moose;
__PACKAGE__->meta->make_immutable;

