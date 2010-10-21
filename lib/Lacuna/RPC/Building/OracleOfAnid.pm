package Lacuna::RPC::Building::OracleOfAnid;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/oracleofanid';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::OracleOfAnid';
}

no Moose;
__PACKAGE__->meta->make_immutable;

