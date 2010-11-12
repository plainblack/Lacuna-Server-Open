package Lacuna::DB::Result::Log::RPC;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Log::WithEmpire';
use Lacuna::Util;

__PACKAGE__->table('rpc_log');
__PACKAGE__->add_columns(
    api_key             => { data_type => 'varchar', size => 40, is_nullable => 1 },
    module              => { data_type => 'varchar', size => 255, is_nullable => 0 },
);

after 'sqlt_deploy_hook' => sub {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_api_key', fields => ['api_key']);
    $sqlt_table->add_index(name => 'idx_module', fields => ['module']);
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
