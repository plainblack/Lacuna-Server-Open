package Lacuna::DB::Body::Planet::P2;

use Moose;
extends 'Lacuna::DB::Body::Planet';


use constant image => 'p2';
use constant surface => 'surface-d';

use constant water => 9100;

# resource concentrations

use constant gypsum => 1500;

use constant trona => 1500;

use constant sulfur => 2300;

use constant methane => 2700;

use constant magnetite => 1000;

use constant fluorite => 190;

use constant beryl => 310;

use constant zircon => 120;

use constant monazite => 130;

use constant gold => 250;


no Moose;
__PACKAGE__->meta->make_immutable;

