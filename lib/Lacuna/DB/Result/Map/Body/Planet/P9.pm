package Lacuna::DB::Result::Map::Body::Planet::P9;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';

use constant image => 'p9';

use constant water => 5304;

# resource concentrations
use constant rutile => 800;

use constant chromite => 900;

use constant chalcopyrite => 100;

use constant galena => 200;

use constant uraninite => 400;

use constant bauxite => 300;

use constant goethite => 200;

use constant halite => 500;

use constant gypsum => 600;

use constant trona => 700;

use constant sulfur => 1600;

use constant methane => 1700;

use constant kerogen => 1800;

use constant anthracite => 100;

use constant magnetite => 100;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

