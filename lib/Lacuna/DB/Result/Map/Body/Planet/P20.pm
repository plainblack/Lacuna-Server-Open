package Lacuna::DB::Result::Map::Body::Planet::P20;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';


use constant image => 'p20';

use constant water => 7608;

# resource concentrations
use constant rutile => 2800;

use constant chromite => 1400;
use constant galena => 3100;
use constant bauxite => 900;
use constant magnetite => 1800;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

