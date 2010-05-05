package Lacuna::DB::Body::Planet::P1;

use Moose;
extends 'Lacuna::DB::Body::Planet';

use constant image => 'p1';
use constant surface => 'surface-a';

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

