package Lacuna::DB::Result::Map::Body::Planet::P18;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';


use constant image => 'p18';

use constant water => 7600;

# resource concentrations

use constant chromite => 3200;

use constant uraninite => 2600;

use constant bauxite => 4200;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

