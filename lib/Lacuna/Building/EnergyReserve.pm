package Lacuna::Building::EnergyReserve;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Energy::Reserve';
}

no Moose;
__PACKAGE__->meta->make_immutable;

