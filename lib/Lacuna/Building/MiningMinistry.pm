package Lacuna::Building::MiningMinistry;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/miningministry';
}

sub model_class {
    return 'Lacuna::DB::Building::Ore::Ministry';
}

no Moose;
__PACKAGE__->meta->make_immutable;

