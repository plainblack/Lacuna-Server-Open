package Lacuna::Building::Singularity;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/singularity';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Energy::Singularity';
}

no Moose;
__PACKAGE__->meta->make_immutable;

