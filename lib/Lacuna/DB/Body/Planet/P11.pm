package Lacuna::DB::Body::Planet::P11;

use Moose;
extends 'Lacuna::DB::Body::Planet';



use constant image => 'p11';

use constant water => 3800;


# resource concentrations

use constant chromite => 1000;

use constant galena => 1000;

use constant uraninite => 1000;

use constant goethite => 1000;

use constant gypsum => 1000;

use constant kerogen => 1000;

use constant anthracite => 1000;

use constant zircon => 1000;

use constant fluorite => 1000;

use constant magnetite => 1000;

no Moose;
__PACKAGE__->meta->make_immutable;

