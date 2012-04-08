package Lacuna::DB::Result::Map::Body::Planet::P39;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';

use constant image => 'p39';

use constant water          => 7135;
use constant rutile         => 1;
use constant chromite       => 1;
use constant chalcopyrite   => 1;
use constant galena         => 1;
use constant gold           => 1;
use constant uraninite      => 1;
use constant bauxite        => 1;
use constant goethite       => 1;
use constant halite         => 1;
use constant gypsum         => 500;
use constant trona          => 1;
use constant sulfur         => 2000;
use constant methane        => 4000;
use constant kerogen        => 1500;
use constant anthracite     => 500;
use constant magnetite      => 1;
use constant fluorite       => 1;
use constant beryl          => 1;
use constant zircon         => 1;
use constant monazite       => 1500;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

