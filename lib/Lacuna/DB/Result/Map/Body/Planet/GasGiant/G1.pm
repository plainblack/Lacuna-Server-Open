package Lacuna::DB::Result::Map::Body::Planet::GasGiant::G1;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet::GasGiant';

use constant image => 'pg1';


use constant rutile => 14000;

use constant chromite => 4000;

use constant chalcopyrite => 2000;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

