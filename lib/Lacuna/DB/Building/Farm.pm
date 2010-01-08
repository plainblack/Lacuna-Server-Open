package Lacuna::DB::Building::Farm;

use Moose;
extends 'Lacuna::DB::Building';

__PACKAGE__->set_domain_name('farm');


no Moose;
__PACKAGE__->meta->make_immutable;
