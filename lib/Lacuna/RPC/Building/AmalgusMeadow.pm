package Lacuna::RPC::Building::AmalgusMeadow;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/amalgusmeadow';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::AmalgusMeadow';
}

no Moose;
__PACKAGE__->meta->make_immutable;
