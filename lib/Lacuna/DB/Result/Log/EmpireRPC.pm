package Lacuna::DB::Result::Log::EmpireRPC;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Log::WithEmpire';
use Lacuna::Util;

__PACKAGE__->table('empire_rpc_log');
__PACKAGE__->add_columns(
    rpc     => { data_type => 'int', size => 11, is_nullable => 0, default_value => 0 },
    limits  => { data_type => 'int', size => 11, is_nullable => 0, default_value => 0 },
);

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
