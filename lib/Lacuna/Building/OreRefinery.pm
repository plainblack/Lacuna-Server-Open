package Lacuna::Building::OreRefinery;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/orerefinery';
}

sub model_class {
    return 'Lacuna::DB::Building::Ore::Refinery';
}

no Moose;
__PACKAGE__->meta->make_immutable;

