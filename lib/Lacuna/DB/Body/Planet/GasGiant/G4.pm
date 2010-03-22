package Lacuna::DB::Body::Planet::GasGiant::G4;

use Moose;
extends 'Lacuna::DB::Body::Planet::GasGiant';

use constant image => 'pg4';

use constant chalcopyrite => 1000;

use constant sulfur => 2000;

use constant magnetite => 7000;



no Moose;
__PACKAGE__->meta->make_immutable;

