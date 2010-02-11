package Lacuna::Building::WaterPurification;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/waterpurification';
}

sub model_class {
    return 'Lacuna::DB::Building::Water::Purification';
}

no Moose;
__PACKAGE__->meta->make_immutable;

