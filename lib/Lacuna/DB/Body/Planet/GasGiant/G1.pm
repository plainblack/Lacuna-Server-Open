package Lacuna::DB::Body::Planet::GasGiant::G1;

use Moose;
extends 'Lacuna::DB::Body::Planet::GasGiant';

use constant image => 'pg1';
use constant surface => 'surface-g';


use constant rutile => 14000;

use constant chromite => 4000;

use constant chalcopyrite => 2000;


no Moose;
__PACKAGE__->meta->make_immutable;

