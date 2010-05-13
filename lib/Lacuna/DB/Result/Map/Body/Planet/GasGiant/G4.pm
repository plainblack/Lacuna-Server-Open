package Lacuna::DB::Result::Map::Body::Planet::GasGiant::G4;

use Moose;
extends 'Lacuna::DB::Result::Map::Body::Planet::GasGiant';

use constant image => 'pg4';
use constant surface => 'surface-g';


use constant chalcopyrite => 2000;

use constant sulfur => 4000;

use constant magnetite => 14000;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

