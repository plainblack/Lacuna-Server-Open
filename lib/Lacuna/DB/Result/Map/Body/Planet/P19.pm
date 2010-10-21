package Lacuna::DB::Result::Map::Body::Planet::P19;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';


use constant image => 'p19';

use constant water => 5390;

# resource concentrations
use constant rutile => 700;

use constant chromite => 100;

use constant chalcopyrite => 700;

use constant galena => 200;

use constant uraninite => 700;

use constant bauxite => 300;

use constant goethite => 700;

use constant halite => 400;

use constant gypsum => 700;

use constant trona => 500;

use constant sulfur => 700;

use constant methane => 600;

use constant kerogen => 1200;

use constant anthracite => 1100;

use constant magnetite => 1400;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

