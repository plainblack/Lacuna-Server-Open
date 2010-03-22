package Lacuna::DB::Body::Planet::P7;

use Moose;
extends 'Lacuna::DB::Body::Planet';

use constant image => 'p7';

use constant water => 4700;

# resource concentrations

use constant chalcopyrite => 2800;

use constant bauxite => 2700;

use constant goethite => 2400;

use constant gypsum => 2100;



no Moose;
__PACKAGE__->meta->make_immutable;

