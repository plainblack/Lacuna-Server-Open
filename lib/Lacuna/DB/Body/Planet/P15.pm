package Lacuna::DB::Body::Planet::P15;

use Moose;
extends 'Lacuna::DB::Body::Planet';


use constant image => 'p15';
use constant surface => 'surface-c';

use constant water => 9018;

# resource concentrations
use constant rutile => 200;

use constant chromite => 300;

use constant chalcopyrite => 100;

use constant galena => 400;

use constant uraninite => 250;

use constant bauxite => 250;

use constant goethite => 4500;

use constant halite => 500;

use constant gypsum => 500;

use constant trona => 330;

use constant sulfur => 270;

use constant methane => 500;

use constant magnetite => 2000;


no Moose;
__PACKAGE__->meta->make_immutable;

