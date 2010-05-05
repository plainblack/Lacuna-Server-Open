package Lacuna::Building::GasGiantLab;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/gasgiantlab';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::GasGiantLab';
}

no Moose;
__PACKAGE__->meta->make_immutable;

