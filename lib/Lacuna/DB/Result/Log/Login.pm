package Lacuna::DB::Result::Log::Login;

use Moose;
extends 'Lacuna::DB::Result::Log';
use Lacuna::Util;

__PACKAGE__->table('login_log');
__PACKAGE__->add_columns(
    api_key             => { data_type => 'char', size => 40, is_nullable => 1 },
    session_id          => { data_type => 'char', size => 40, is_nullable => 0 },
    log_out_date        => { data_type => 'datetime', is_nullable => 1 },
    extended            => { data_type => 'int', size => 11, default_value => 0 },
);

after 'sqlt_deploy_hook' => sub {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_api_key', fields => ['api_key']);
    $sqlt_table->add_index(name => 'idx_session_id', fields => ['session_id']);
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
