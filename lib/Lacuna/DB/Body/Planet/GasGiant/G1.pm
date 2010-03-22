package Lacuna::DB::Body::Planet::GasGiant::G1;

use Moose;
extends 'Lacuna::DB::Body::Planet::GasGiant';

use constant image => 'pg1';


use constant rutile => 7000;

use constant chromite => 2000;

use constant chalcopyrite => 1000;


no Moose;
__PACKAGE__->meta->make_immutable;

