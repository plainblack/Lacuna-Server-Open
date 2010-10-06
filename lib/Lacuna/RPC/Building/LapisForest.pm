package Lacuna::RPC::Building::LapisForest;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/lapisforest';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::LapisForest';
}

no Moose;
__PACKAGE__->meta->make_immutable;

