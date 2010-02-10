package Lacuna::Building::Mine;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Ore::Mine';
}

no Moose;
__PACKAGE__->meta->make_immutable;

