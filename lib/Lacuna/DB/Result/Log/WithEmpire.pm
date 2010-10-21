package Lacuna::DB::Result::Log::WithEmpire;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Log';
use Lacuna::Util;

__PACKAGE__->table('noexist_with_empire_log');
__PACKAGE__->add_columns(
    empire_id               => { data_type => 'int', size => 11, is_nullable => 0 },
    empire_name             => { data_type => 'varchar', size => 30, is_nullable => 0 },
);

after 'sqlt_deploy_hook' => sub {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_empire_id', fields => ['empire_id']);
    $sqlt_table->add_index(name => 'idx_empire_name', fields => ['empire_name']);
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
