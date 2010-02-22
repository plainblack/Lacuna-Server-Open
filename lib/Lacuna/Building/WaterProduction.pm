package Lacuna::Building::WaterProduction;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/waterproduction';
}

sub model_class {
    return 'Lacuna::DB::Building::Water::Production';
}

no Moose;
__PACKAGE__->meta->make_immutable;

