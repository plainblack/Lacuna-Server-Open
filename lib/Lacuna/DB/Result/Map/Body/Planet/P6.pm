package Lacuna::DB::Result::Map::Body::Planet::P6;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';

use constant image => 'p6';

use constant water => 6905;

# resource concentrations

use constant goethite => 1400;

use constant halite => 1000;

use constant gypsum => 1500;

use constant trona => 1300;

use constant sulfur => 1700;

use constant methane => 1200;

use constant magnetite => 1900;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

