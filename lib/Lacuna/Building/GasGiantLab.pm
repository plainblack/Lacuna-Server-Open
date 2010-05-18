package Lacuna::RPC::Building::GasGiantLab;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/gasgiantlab';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::GasGiantLab';
}

no Moose;
__PACKAGE__->meta->make_immutable;

