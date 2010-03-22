package Lacuna::DB::Body::Planet::P4;

use Moose;
extends 'Lacuna::DB::Body::Planet';

use constant image => 'p4';

use constant water => 800;

# resource concentrations

use constant chalcopyrite => 1000;

use constant uraninite => 1500;

use constant goethite => 1500;

use constant gypsum => 1500;

use constant sulfur => 1500;

use constant kerogen => 1500;

use constant magnetite => 1500;


no Moose;
__PACKAGE__->meta->make_immutable;

