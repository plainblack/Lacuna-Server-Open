package Lacuna::Building::WaterProduction;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Water::Production';
}

no Moose;
__PACKAGE__->meta->make_immutable;

