package Lacuna::DB::Result::Map::Body::Planet::P8;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';

use constant image => 'p8';

use constant water => 5100;

# resource concentrations

use constant halite => 1300;

use constant gypsum => 1250;

use constant trona => 1250;

use constant sulfur => 1;

use constant methane => 1;

use constant kerogen => 3100;

use constant anthracite => 3100;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

