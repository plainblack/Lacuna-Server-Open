package Lacuna::DB::Building::Energy;

use Moose;
extends 'Lacuna::DB::Building';

__PACKAGE__->set_domain_name('energy');


no Moose;
__PACKAGE__->meta->make_immutable;
