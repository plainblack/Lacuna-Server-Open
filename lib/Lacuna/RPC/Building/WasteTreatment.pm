package Lacuna::RPC::Building::WasteTreatment;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/wastetreatment';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Waste::Treatment';
}

no Moose;
__PACKAGE__->meta->make_immutable;

