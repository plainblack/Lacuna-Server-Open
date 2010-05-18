package Lacuna::RPC::Building::EnergyReserve;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/energyreserve';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Energy::Reserve';
}

no Moose;
__PACKAGE__->meta->make_immutable;

