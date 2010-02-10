package Lacuna::Building::Intelligence;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Intelligence';
}

no Moose;
__PACKAGE__->meta->make_immutable;

