package Lacuna::DB::Building::Water;

use Moose;
extends 'Lacuna::DB::Building';

__PACKAGE__->set_domain_name('water');


no Moose;
__PACKAGE__->meta->make_immutable;
