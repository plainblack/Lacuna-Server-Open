package Lacuna::DB::Result::Map::Body::Planet::P14;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';


use constant image => 'p14';

use constant water => 5010;

# resource concentrations
use constant rutile => 100;

use constant chromite => 100;

use constant chalcopyrite => 100;

use constant galena => 100;

use constant uraninite => 100;

use constant bauxite => 100;

use constant goethite => 100;

use constant halite => 100;

use constant gypsum => 100;

use constant trona => 4000;

use constant sulfur => 2300;

use constant methane => 2700;

use constant magnetite => 100;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

