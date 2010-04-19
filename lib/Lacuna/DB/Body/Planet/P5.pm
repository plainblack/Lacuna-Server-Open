package Lacuna::DB::Body::Planet::P5;

use Moose;
extends 'Lacuna::DB::Body::Planet';

use constant image => 'p5';
use constant surface => 'surface-f';

use constant water => 6200;

# resource concentrations
use constant rutile => 1250;

use constant chalcopyrite => 250;

use constant galena => 2250;

use constant uraninite => 250;

use constant bauxite => 2250;

use constant goethite => 1250;

use constant halite => 250;

use constant gypsum => 1250;

use constant trona => 250;

use constant sulfur => 250;

use constant methane => 250;

use constant magnetite => 250;


no Moose;
__PACKAGE__->meta->make_immutable;

