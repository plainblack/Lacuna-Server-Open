package Lacuna::Building::GasGiantLab;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::GasGiantLab';
}

no Moose;
__PACKAGE__->meta->make_immutable;

