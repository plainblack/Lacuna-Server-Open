package Lacuna::DB::Result::Building::Permanent;

use Moose;
extends 'Lacuna::DB::Result::Building';

sub build_tags {}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
