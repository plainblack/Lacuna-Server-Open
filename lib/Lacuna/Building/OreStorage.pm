package Lacuna::Building::OreStorage;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Ore::Storage';
}

no Moose;
__PACKAGE__->meta->make_immutable;

