package Lacuna::Building::WaterPurification;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Water::Purification';
}

no Moose;
__PACKAGE__->meta->make_immutable;

