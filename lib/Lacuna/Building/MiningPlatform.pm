package Lacuna::Building::MiningPlatform;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Ore::Platform';
}

no Moose;
__PACKAGE__->meta->make_immutable;

