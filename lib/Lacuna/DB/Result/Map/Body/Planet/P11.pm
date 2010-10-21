package Lacuna::DB::Result::Map::Body::Planet::P11;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';



use constant image => 'p11';

use constant water => 8400;


# resource concentrations

use constant chromite => 1000;

use constant galena => 1000;

use constant uraninite => 1000;

use constant goethite => 1000;

use constant gypsum => 1000;

use constant kerogen => 1000;

use constant anthracite => 1000;

use constant zircon => 1000;

use constant fluorite => 1000;

use constant magnetite => 1000;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

