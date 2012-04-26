package Lacuna::DB::Result::Map::Body::Asteroid::A22;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Asteroid';

use constant image => 'a22';

use constant rutile         => 800;
use constant chromite       => 900;
use constant chalcopyrite   => 700;
use constant galena         => 800;
use constant gold           => 100;
use constant uraninite      => 1;
use constant bauxite        => 900;
use constant goethite       => 400;
use constant halite         => 1;
use constant gypsum         => 1;
use constant trona          => 400;
use constant sulfur         => 1;
use constant methane        => 1;
use constant kerogen        => 1;
use constant anthracite     => 1;
use constant magnetite      => 500;
use constant fluorite       => 100;
use constant beryl          => 1;
use constant zircon         => 200;
use constant monazite       => 300;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

