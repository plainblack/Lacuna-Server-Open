package Lacuna::DB::Result::Map::Body::Planet::P17;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';


use constant image => 'p17';

use constant water => 10000;

# resource concentrations

use constant trona => 3900;

use constant methane => 1900;

use constant magnetite => 4200;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

