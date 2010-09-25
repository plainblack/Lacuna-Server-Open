package Lacuna::DB::Result::ViralLog;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util;

__PACKAGE__->table('viral_log');
__PACKAGE__->add_columns(
    date_stamp         => { data_type => 'date', is_nullable => 0 },
    total_users        => { data_type => 'int', size => 11, default_value => 0 },
    creates            => { data_type => 'int', size => 11, default_value => 0 },
    invites            => { data_type => 'int', size => 11, default_value => 0 },
    accepts            => { data_type => 'int', size => 11, default_value => 0 },
    deletes            => { data_type => 'int', size => 11, default_value => 0 },
    active_duration    => { data_type => 'int', size => 11, default_value => 0 },
);

after 'sqlt_deploy_hook' => sub {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_date_stamp', fields => ['date_stamp']);
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
