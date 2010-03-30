package Lacuna::DB::Body::Planet::GasGiant::G4;

use Moose;
extends 'Lacuna::DB::Body::Planet::GasGiant';

use constant image => 'pg4';

use constant chalcopyrite => 2000;

use constant sulfur => 4000;

use constant magnetite => 14000;



no Moose;
__PACKAGE__->meta->make_immutable;

