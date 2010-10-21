package Lacuna::RPC::Building::Beach10;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/beach10';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::Beach10';
}

no Moose;
__PACKAGE__->meta->make_immutable;

