package Lacuna::DB::Result::Log::Lottery;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Log::WithEmpire';
use Lacuna::Util;

__PACKAGE__->table('lottery_log');
__PACKAGE__->add_columns(
    api_key             => { data_type => 'varchar', size => 40, is_nullable => 1 },
    url                 => { data_type => 'varchar', size => 255, is_nullable => 0 },
    ip_address          => { data_type => 'varchar', size => 15, is_nullable => 1 },
);

after 'sqlt_deploy_hook' => sub {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_api_key', fields => ['api_key']);
    $sqlt_table->add_index(name => 'idx_url', fields => ['url']);
    $sqlt_table->add_index(name => 'idx_ip_address', fields => ['ip_address']);
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
