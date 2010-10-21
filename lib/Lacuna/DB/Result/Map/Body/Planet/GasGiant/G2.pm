package Lacuna::DB::Result::Map::Body::Planet::GasGiant::G2;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet::GasGiant';

use constant image => 'pg2';



use constant galena => 14000;

use constant bauxite => 4000;

use constant goethite => 2000;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

