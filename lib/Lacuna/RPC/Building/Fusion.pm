package Lacuna::RPC::Building::Fusion;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/fusion';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Energy::Fusion';
}

no Moose;
__PACKAGE__->meta->make_immutable;

