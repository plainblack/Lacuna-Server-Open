package Lacuna::DB::Result::Log;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util;

__PACKAGE__->table('noexist_log');
__PACKAGE__->add_columns(
    date_stamp              => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
