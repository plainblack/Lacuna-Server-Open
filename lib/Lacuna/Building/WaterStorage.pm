package Lacuna::Building::WaterStorage;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Water::Storage';
}

no Moose;
__PACKAGE__->meta->make_immutable;

