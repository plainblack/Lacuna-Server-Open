package Lacuna::Building::Propulsion;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Propulsion';
}

no Moose;
__PACKAGE__->meta->make_immutable;

