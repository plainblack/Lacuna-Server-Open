package Lacuna::DB::Result::Map::Body::Planet::P7;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';

use constant image => 'p7';

use constant water => 5700;

# resource concentrations

use constant chalcopyrite => 2800;

use constant bauxite => 1700;

use constant goethite => 2400;

use constant gypsum => 2100;

use constant beryl => 1000;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

