package Lacuna::RPC::Building::Singularity;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/singularity';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Energy::Singularity';
}

no Moose;
__PACKAGE__->meta->make_immutable;

