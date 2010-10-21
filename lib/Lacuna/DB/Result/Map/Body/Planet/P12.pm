package Lacuna::DB::Result::Map::Body::Planet::P12;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';

use constant image => 'p12';

use constant water => 5600;


# resource concentrations
use constant rutile => 1000;

use constant chalcopyrite => 1000;

use constant gold => 1000;

use constant bauxite => 1000;

use constant halite => 1000;

use constant trona => 1000;

use constant methane => 1000;

use constant sulfur => 1000;

use constant monazite => 1000;

use constant beryl => 1000;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

