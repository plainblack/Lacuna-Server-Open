package Lacuna::DB::Result::Map::Body::Planet::P13;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';


use constant image => 'p13';

use constant water => 8300;

# resource concentrations
use constant rutile => 2100;

use constant chromite => 1400;

use constant chalcopyrite => 1300;

use constant galena => 2200;

use constant kerogen => 1500;

use constant anthracite => 1500;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

