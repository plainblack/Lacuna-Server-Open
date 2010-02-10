package Lacuna::Building::OreRefinery;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Ore::Refinery';
}

no Moose;
__PACKAGE__->meta->make_immutable;

