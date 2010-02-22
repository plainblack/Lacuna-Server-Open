package Lacuna::DB::Building::Permanent;

use Moose;
extends 'Lacuna::DB::Building';

__PACKAGE__->set_domain_name('permanent');


no Moose;
__PACKAGE__->meta->make_immutable;
