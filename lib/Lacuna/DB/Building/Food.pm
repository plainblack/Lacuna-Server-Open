package Lacuna::DB::Building::Food;

use Moose;
extends 'Lacuna::DB::Building';

__PACKAGE__->set_domain_name('food');


no Moose;
__PACKAGE__->meta->make_immutable;
