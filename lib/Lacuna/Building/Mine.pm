package Lacuna::Building::Mine;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/mine';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Ore::Mine';
}

no Moose;
__PACKAGE__->meta->make_immutable;

