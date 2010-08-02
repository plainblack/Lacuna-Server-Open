package Lacuna::RPC::Building::Beach3;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/beach3';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::Beach3';
}

no Moose;
__PACKAGE__->meta->make_immutable;

