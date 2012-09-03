package Lacuna::DB::Result::Config;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util;

__PACKAGE__->table('config');
__PACKAGE__->add_columns(
    name        => { data_type => 'varchar', size => 30, is_nullable => 0 },
    value       => { data_type => 'varchar', size => 256, is_nullable => 0 },
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'c_idx_key', fields => ['name']);
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
