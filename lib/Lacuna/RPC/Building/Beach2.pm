package Lacuna::RPC::Building::Beach2;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/beach2';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::Beach2';
}

no Moose;
__PACKAGE__->meta->make_immutable;

