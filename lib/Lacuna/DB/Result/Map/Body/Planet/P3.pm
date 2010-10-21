package Lacuna::DB::Result::Map::Body::Planet::P3;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';


use constant image => 'p3';

use constant water => 5555;

# resource concentrations

use constant uraninite => 3000;

use constant methane => 2900;

use constant kerogen => 1400;

use constant anthracite => 1700;

use constant zircon => 1000;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

