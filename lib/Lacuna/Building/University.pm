package Lacuna::Building::University;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::University';
}

no Moose;
__PACKAGE__->meta->make_immutable;

