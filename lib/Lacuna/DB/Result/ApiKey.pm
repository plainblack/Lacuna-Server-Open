package Lacuna::DB::Result::ApiKey;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util;

__PACKAGE__->table('api_key');
__PACKAGE__->add_columns(
    date_stamp              => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    public_key              => { data_type => 'varchar', size => 36, is_nullable => 0 },
    private_key             => { data_type => 'varchar', size => 36, is_nullable => 0 },
    name                    => { data_type => 'varchar', size => 30, is_nullable => 1 },
    ip_address              => { data_type => 'varchar', size => 15, is_nullable => 1 },
    email                   => { data_type => 'varchar', size => 255, is_nullable => 1 },
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_private_key', fields => ['private_key']);
    $sqlt_table->add_index(name => 'idx_public_key', fields => ['public_key']);
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
