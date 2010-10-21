package Lacuna::DB::Result::Map::Body::Planet::GasGiant::G4;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet::GasGiant';

use constant image => 'pg4';


use constant chalcopyrite => 2000;

use constant sulfur => 4000;

use constant magnetite => 14000;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

