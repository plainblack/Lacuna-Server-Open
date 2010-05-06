package Lacuna::DB::Result::Building::Food::Farm;

use Moose;
extends 'Lacuna::DB::Result::Building::Food';

sub build_tags {}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
