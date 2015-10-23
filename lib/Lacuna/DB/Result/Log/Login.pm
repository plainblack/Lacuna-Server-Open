package Lacuna::DB::Result::Log::Login;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Log::WithEmpire';
use Lacuna::Util;

__PACKAGE__->table('login_log');
__PACKAGE__->add_columns(
    api_key             => { data_type => 'varchar', size => 36, is_nullable => 1 },
    session_id          => { data_type => 'char', size => 36, is_nullable => 0 },
    ip_address          => { data_type => 'varchar', size => 15, is_nullable => 1 },
    log_out_date        => { data_type => 'datetime', is_nullable => 1 },
    extended            => { data_type => 'int', size => 11, default_value => 0 },
    is_sitter           => { data_type => 'int', size => 1, is_nullable => 0, default_value => 0 },
    browser_fingerprint => { data_type => 'varchar', size => 32, is_nullable => 1 },
);

after 'sqlt_deploy_hook' => sub {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_api_key', fields => ['api_key']);
    $sqlt_table->add_index(name => 'idx_session_id', fields => ['session_id']);
    $sqlt_table->add_index(name => 'idx_fingerprint', fields => ['browser_fingerprint']);
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
