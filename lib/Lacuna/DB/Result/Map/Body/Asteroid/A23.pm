package Lacuna::DB::Result::Map::Body::Asteroid::A23;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Asteroid';

use constant image => 'a23';

use constant rutile         => 1000;
use constant chromite       => 1000;
use constant chalcopyrite   => 1000;
use constant galena         => 1000;
use constant gold           => 1;
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
use constant fluorite       => 1000;
use constant beryl          => 1000;
use constant zircon         => 1000;
use constant monazite       => 1;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

