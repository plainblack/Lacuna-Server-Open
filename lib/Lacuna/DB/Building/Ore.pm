package Lacuna::DB::Building::Ore;

use Moose;
extends 'Lacuna::DB::Building';

__PACKAGE__->set_domain_name('ore');


no Moose;
__PACKAGE__->meta->make_immutable;
