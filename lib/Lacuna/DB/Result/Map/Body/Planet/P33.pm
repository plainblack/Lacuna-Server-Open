package Lacuna::DB::Result::Map::Body::Planet::P33;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';
use Lacuna::Util;

use constant image => 'p33';

sub water          { randint(1000,10000) }
sub rutile         { randint(1,1000) }
sub chromite       { randint(1,1000) }
sub chalcopyrite   { randint(1,1000) }
sub galena         { randint(1,1000) }
sub gold           { randint(1,1000) }
sub uraninite      { randint(1,1000) }
sub bauxite        { randint(1,1000) }
sub goethite       { randint(1,1000) }
sub halite         { randint(1,1000) }
sub gypsum         { randint(1,1000) }
sub trona          { randint(1,1000) }
sub sulfur         { randint(1,1000) }
sub methane        { randint(1,1000) }
sub kerogen        { randint(1,1000) }
sub anthracite     { randint(1,1000) }
sub magnetite      { randint(1,1000) }
sub fluorite       { randint(1,1000) }
sub beryl          { randint(1,1000) }
sub zircon         { randint(1,1000) }
sub monazite       { randint(1,1000) }


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

