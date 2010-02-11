package Lacuna::Building::OreStorage;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/orestorage';
}

sub model_class {
    return 'Lacuna::DB::Building::Ore::Storage';
}

no Moose;
__PACKAGE__->meta->make_immutable;

