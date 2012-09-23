package Lacuna::DB::Result::Map::Body::Planet::P36;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';

use constant image => 'p36';

use constant water          => 30000;
use constant rutile         => 100;
use constant chromite       => 100;
use constant chalcopyrite   => 100;
use constant galena         => 1;
use constant gold           => 1;
use constant uraninite      => 1;
use constant bauxite        => 100;
use constant goethite       => 100;
use constant halite         => 1;
use constant gypsum         => 100;
use constant trona          => 1;
use constant sulfur         => 100;
use constant methane        => 1;
use constant kerogen        => 1;
use constant anthracite     => 1;
use constant magnetite      => 1;
use constant fluorite       => 1;
use constant beryl          => 1;
use constant zircon         => 1;
use constant monazite       => 100;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

