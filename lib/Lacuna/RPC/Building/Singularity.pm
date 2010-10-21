package Lacuna::RPC::Building::Singularity;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/singularity';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Energy::Singularity';
}

no Moose;
__PACKAGE__->meta->make_immutable;

