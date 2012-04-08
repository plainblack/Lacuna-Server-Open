package Lacuna::DB::Result::Map::Body::Asteroid::A26;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Asteroid';

use constant image => 'a26';

use constant rutile         => 1;
use constant chromite       => 1;
use constant chalcopyrite   => 1;
use constant galena         => 1;
use constant gold           => 1;
use constant uraninite      => 1750;
use constant bauxite        => 1;
use constant goethite       => 1;
use constant halite         => 1;
use constant gypsum         => 1;
use constant trona          => 1;
use constant sulfur         => 1;
use constant methane        => 1;
use constant kerogen        => 1500;
use constant anthracite     => 1500;
use constant magnetite      => 1500;
use constant fluorite       => 1;
use constant beryl          => 1;
use constant zircon         => 1;
use constant monazite       => 750;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

