package Lacuna::DB::Result::EssentiaCode;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util;

__PACKAGE__->table('essentia_code');
__PACKAGE__->add_columns(
    code                    => { data_type => 'varchar', size => 36, is_nullable => 0 },
    amount                  => { data_type => 'float', size => [11,1], is_nullable => 0 },
    date_created            => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    description             => { data_type => 'varchar', size => 50, is_nullable => 0 },
    used                    => { data_type => 'tinyint', is_nullable => 0, default_value => 0 },
    empire_id               => { data_type => 'int', size => 11, is_nullable => 0 },
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_code', fields => ['code']);
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
