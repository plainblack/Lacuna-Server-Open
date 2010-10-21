package Lacuna::DB::Result::Map::Body::Planet::P10;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';

use constant image => 'p10';

use constant water => 6800;

# resource concentrations

use constant goethite => 1000;

use constant gypsum => 500;

use constant trona => 500;

use constant kerogen => 500;

use constant methane => 500;

use constant anthracite => 500;

use constant sulfur => 500;

use constant zircon => 250;

use constant monazite => 250;

use constant fluorite => 250;

use constant beryl => 250;

use constant magnetite => 5000;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

