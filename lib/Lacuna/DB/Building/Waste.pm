package Lacuna::DB::Building::Waste;

use Moose;
extends 'Lacuna::DB::Building';

__PACKAGE__->set_domain_name('waste');


no Moose;
__PACKAGE__->meta->make_immutable;
