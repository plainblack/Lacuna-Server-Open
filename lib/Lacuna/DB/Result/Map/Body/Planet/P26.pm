package Lacuna::DB::Result::Map::Body::Planet::P26;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';

use constant image => 'p26';

use constant water          => 7800;
use constant rutile         => 100;
use constant chromite       => 100;
use constant chalcopyrite   => 100;
use constant galena         => 100;
use constant gold           => 9000;
use constant uraninite      => 1;
use constant bauxite        => 1;
use constant goethite       => 100;
use constant halite         => 100;
use constant gypsum         => 100;
use constant trona          => 1;
use constant sulfur         => 1;
use constant methane        => 100;
use constant kerogen        => 100;
use constant anthracite     => 1;
use constant magnetite      => 100;
use constant fluorite       => 1;
use constant beryl          => 1;
use constant zircon         => 1;
use constant monazite       => 1;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

