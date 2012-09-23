package Lacuna::DB::Result::Map::Body::Planet::P33;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';
use Lacuna::Util qw(randint);

with "Lacuna::Role::Planet::Weather";
with "Lacuna::Role::Planet::GeoChaos";

use constant image => 'p33';

sub water           { return 6000; };
sub anthracite      { return 1000; };
sub bauxite         { return 1000; };
sub beryl           { return 1000; };
sub chalcopyrite    { return 1000; };
sub chromite        { return 1000; };
sub fluorite        { return 1000; };
sub galena          { return 1000; };
sub goethite        { return 1000; };
sub gold            { return 1000; };
sub gypsum          { return 1000; };
sub halite          { return 1000; };
sub kerogen         { return 1000; };
sub magnetite       { return 1000; };
sub methane         { return 1000; };
sub monazite        { return 1000; };
sub rutile          { return 1000; };
sub sulfur          { return 1000; };
sub trona           { return 1000; };
sub uraninite       { return 1000; };
sub zircon          { return 1000; };


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

