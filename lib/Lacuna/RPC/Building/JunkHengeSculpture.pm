package Lacuna::RPC::Building::JunkHengeSculpture;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/junkhengesculpture';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::JunkHengeSculpture';
}

no Moose;
__PACKAGE__->meta->make_immutable;

