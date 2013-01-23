package Lacuna::DB::Result::Log::EmpireNameChange;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Log::WithEmpire';
use Lacuna::Util;

__PACKAGE__->table('empire_name_change_log');
__PACKAGE__->add_columns(
    old_empire_name             => { data_type => 'varchar', size => 30, is_nullable => 0 },
);

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

