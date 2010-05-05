package Lacuna::DB::Building::Food::Factory;

use Moose;
extends 'Lacuna::DB::Building::Food';

has converts_food => (
    is      => 'ro',
    default => undef,
);


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
