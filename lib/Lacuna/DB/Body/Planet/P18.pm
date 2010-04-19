package Lacuna::DB::Body::Planet::P18;

use Moose;
extends 'Lacuna::DB::Body::Planet';


use constant image => 'p18';
use constant surface => 'surface-d';

use constant water => 7600;

# resource concentrations

use constant chromite => 3200;

use constant uraninite => 2600;

use constant bauxite => 4200;


no Moose;
__PACKAGE__->meta->make_immutable;

