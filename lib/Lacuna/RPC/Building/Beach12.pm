package Lacuna::RPC::Building::Beach12;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/beach12';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::Beach12';
}

no Moose;
__PACKAGE__->meta->make_immutable;

