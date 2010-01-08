package Lacuna::DB::Building::Factory;

use Moose;
extends 'Lacuna::DB::Building';

__PACKAGE__->set_domain_name('factory');

has converts_food => (
    is      => 'ro',
    default => undef,
);


no Moose;
__PACKAGE__->meta->make_immutable;
