package Lacuna::RPC::Building::SupplyPod;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/supplypod';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::SupplyPod';
}

no Moose;
__PACKAGE__->meta->make_immutable;

