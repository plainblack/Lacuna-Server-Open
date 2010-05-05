package Lacuna::Building::Pancake;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/pancake';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Factory::Pancake';
}

no Moose;
__PACKAGE__->meta->make_immutable;

