package Lacuna::RPC::Building::Beach5;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/beach5';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::Beach5';
}

no Moose;
__PACKAGE__->meta->make_immutable;

