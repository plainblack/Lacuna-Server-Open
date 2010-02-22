package Lacuna::Building::WaterStorage;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/waterstorage';
}

sub model_class {
    return 'Lacuna::DB::Building::Water::Storage';
}

no Moose;
__PACKAGE__->meta->make_immutable;

