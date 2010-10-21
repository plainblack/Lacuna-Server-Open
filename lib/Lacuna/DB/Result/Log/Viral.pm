package Lacuna::DB::Result::Log::Viral;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util;

__PACKAGE__->table('viral_log');
__PACKAGE__->add_columns(
    date_stamp         => { data_type => 'date', is_nullable => 0 },
    total_users        => { data_type => 'int', default_value => 0 },
    creates            => { data_type => 'int', default_value => 0 },
    invites            => { data_type => 'int', default_value => 0 },
    accepts            => { data_type => 'int', default_value => 0 },
    deletes            => { data_type => 'int', default_value => 0 },
    abandons          => { data_type => 'int', default_value => 0 },
    active_duration    => { data_type => 'int', default_value => 0 },
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_date_stamp', fields => ['date_stamp']);
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
