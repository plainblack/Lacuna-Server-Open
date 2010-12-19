package Lacuna::RPC::Building::DeployedBleeder;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/deployedbleeder';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::DeployedBleeder';
}

no Moose;
__PACKAGE__->meta->make_immutable;

