package Lacuna::DB::Result::Body::Planet::P17;

use Moose;
extends 'Lacuna::DB::Result::Body::Planet';


use constant image => 'p17';
use constant surface => 'surface-c';

use constant water => 10000;

# resource concentrations

use constant trona => 3900;

use constant methane => 1900;

use constant magnetite => 4200;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

