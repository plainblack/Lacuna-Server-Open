package Lacuna::DB::Body::Planet::P3;

use Moose;
extends 'Lacuna::DB::Body::Planet';


use constant image => 'p3';

use constant water => 555;

# resource concentrations

use constant uraninite => 3000;

use constant methane => 2900;

use constant kerogen => 1400;

use constant anthracite => 2700;

no Moose;
__PACKAGE__->meta->make_immutable;

