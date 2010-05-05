package Lacuna::DB::Building::Food::Farm;

use Moose;
extends 'Lacuna::DB::Building::Food';

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
