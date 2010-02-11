package Lacuna::Building::EnergyReserve;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/energyreserve';
}

sub model_class {
    return 'Lacuna::DB::Building::Energy::Reserve';
}

no Moose;
__PACKAGE__->meta->make_immutable;

