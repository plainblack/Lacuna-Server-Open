package Lacuna::DB::Result::Map::Body::Planet::P35;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';

with "Lacuna::Role::Planet::Weather";

use constant image => 'p35';

sub water           { return 11500; };
use constant rutile         => 500;
use constant chromite       => 500;
use constant chalcopyrite   => 500;
use constant galena         => 500;
use constant gold           => 500;
use constant uraninite      => 500;
use constant bauxite        => 500;
use constant goethite       => 500;
use constant halite         => 500;
use constant gypsum         => 500;
use constant trona          => 500;
use constant sulfur         => 500;
use constant methane        => 500;
use constant kerogen        => 500;
use constant anthracite     => 500;
use constant magnetite      => 500;
use constant fluorite       => 500;
use constant beryl          => 500;
use constant zircon         => 500;
use constant monazite       => 500;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

