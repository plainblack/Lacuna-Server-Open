package Lacuna::DB::Result::Map::Body::Planet;

use Moose;
use Carp;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body';

use DateTime;
use Data::Dumper;
no warnings 'uninitialized';

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
