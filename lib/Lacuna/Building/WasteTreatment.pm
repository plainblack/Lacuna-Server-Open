package Lacuna::Building::WasteTreatment;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/wastetreatment';
}

sub model_class {
    return 'Lacuna::DB::Building::Waste::Treatment';
}

no Moose;
__PACKAGE__->meta->make_immutable;

