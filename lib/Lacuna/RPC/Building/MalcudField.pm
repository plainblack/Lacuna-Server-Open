package Lacuna::RPC::Building::MalcudField;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/malcudfield';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::MalcudField';
}

no Moose;
__PACKAGE__->meta->make_immutable;

