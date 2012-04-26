package Lacuna::DB::Result::Map::Body::Planet::P25;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';

use constant image => 'p25';

use constant water          => 9475;
use constant rutile         => 2000;
use constant chromite       => 1000;
use constant chalcopyrite   => 3000;
use constant galena         => 4000;
use constant gold           => 1000;
use constant uraninite      => 1;
use constant bauxite        => 1;
use constant goethite       => 1;
use constant halite         => 1;
use constant gypsum         => 1;
use constant trona          => 1;
use constant sulfur         => 1;
use constant methane        => 1;
use constant kerogen        => 1;
use constant anthracite     => 1;
use constant magnetite      => 1;
use constant fluorite       => 1;
use constant beryl          => 1;
use constant zircon         => 1;
use constant monazite       => 1;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

