package Lacuna::DB::Result::Map::Body::Planet::P15;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';


use constant image => 'p15';

use constant water => 9018;

# resource concentrations
use constant rutile => 200;

use constant chromite => 300;

use constant chalcopyrite => 100;

use constant galena => 400;

use constant uraninite => 250;

use constant bauxite => 250;

use constant goethite => 4500;

use constant halite => 500;

use constant gypsum => 500;

use constant trona => 330;

use constant sulfur => 270;

use constant methane => 500;

use constant magnetite => 2000;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

