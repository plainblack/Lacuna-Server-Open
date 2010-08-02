package Lacuna::DB::Result::Log;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util;

__PACKAGE__->table('noexist_log');
__PACKAGE__->add_columns(
    date_stamp              => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    empire_id               => { data_type => 'int', size => 11, is_nullable => 0 },
    empire_name             => { data_type => 'varchar', size => 30, is_nullable => 0 },
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_empire_id', fields => ['empire_id']);
    $sqlt_table->add_index(name => 'idx_empire_name', fields => ['empire_name']);
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
