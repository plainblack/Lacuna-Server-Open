package Lacuna::DB::Result::Log::Battles;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Log';
use Lacuna::Util;

__PACKAGE__->table('battle_log');
__PACKAGE__->add_columns(
    attacking_empire_id     => { data_type => 'int', size => 11, is_nullable => 0 },
    attacking_empire_name   => { data_type => 'varchar', size => 30, is_nullable => 0 },
    attacking_body_id       => { data_type => 'int', size => 11, is_nullable => 0 },
    attacking_body_name     => { data_type => 'varchar', size => 30, is_nullable => 0 },
    attacking_unit_name     => { data_type => 'varchar', size => 60, is_nullable => 0 },
    defending_empire_id     => { data_type => 'int', size => 11, is_nullable => 0 },
    defending_empire_name   => { data_type => 'varchar', size => 30, is_nullable => 0 },
    defending_body_id       => { data_type => 'int', size => 11, is_nullable => 0 },
    defending_body_name     => { data_type => 'varchar', size => 30, is_nullable => 0 },
    defending_unit_name     => { data_type => 'varchar', size => 60, is_nullable => 0 },
    victory_to              => { data_type => 'varchar', size => 8, is_nullable => 0 },        
);

after 'sqlt_deploy_hook' => sub {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_datestamp', fields => ['datestamp']);
    $sqlt_table->add_index(name => 'idx_attacking_empire_id', fields => ['attacking_empire_id']);
    $sqlt_table->add_index(name => 'idx_attacking_empire_name', fields => ['attacking_empire_name']);
    $sqlt_table->add_index(name => 'idx_attacking_body_id', fields => ['attacking_body_id']);
    $sqlt_table->add_index(name => 'idx_attacking_body_name', fields => ['attacking_body_name']);
    $sqlt_table->add_index(name => 'idx_defending_empire_id', fields => ['defending_empire_id']);
    $sqlt_table->add_index(name => 'idx_defending_empire_name', fields => ['defending_empire_name']);
    $sqlt_table->add_index(name => 'idx_defending_body_id', fields => ['defending_body_id']);
    $sqlt_table->add_index(name => 'idx_defending_body_name', fields => ['defending_body_name']);
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
