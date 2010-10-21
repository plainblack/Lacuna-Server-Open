package Lacuna::DB::Result::Map::Body::Planet::P1;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';

use constant image => 'p1';

use constant water => 7100;

# resource concentrations
use constant rutile => 500;

use constant chromite => 5000;

use constant chalcopyrite => 1000;

use constant galena => 1500;

use constant gold => 500;

use constant uraninite => 250;

use constant bauxite => 250;

use constant goethite => 500;

use constant halite => 250;

use constant gypsum => 250;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

