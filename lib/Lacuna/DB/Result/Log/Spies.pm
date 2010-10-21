package Lacuna::DB::Result::Log::Spies;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Log::WithEmpire';
use Lacuna::Util;

__PACKAGE__->table('spy_log');
__PACKAGE__->add_columns(
    spy_name                    => { data_type => 'varchar', size => 30, is_nullable => 0 },
    spy_id                      => { data_type => 'int', size => 11, is_nullable => 0 },
    planet_name                 => { data_type => 'varchar', size => 30, is_nullable => 0 },
    planet_id                   => { data_type => 'int', size => 11, is_nullable => 0 },
    level                       => { data_type => 'int', size => 11, is_nullable => 0 },
    level_rank                  => { data_type => 'int', size => 11, is_nullable => 0 },
    level_delta                 => { data_type => 'int', size => 11, default_value => 0 },
    offense_success_rate        => { data_type => 'float', size => [6,6], is_nullable => 0 },
    offense_success_rate_delta  => { data_type => 'float', size => [6,6], default_value => 0 },
    defense_success_rate        => { data_type => 'float', size => [6,6], is_nullable => 0 },
    defense_success_rate_delta  => { data_type => 'float', size => [6,6], default_value => 0 },
    success_rate                => { data_type => 'float', size => [6,6], is_nullable => 0 },
    success_rate_rank           => { data_type => 'int', size => 11, is_nullable => 0 },
    success_rate_delta          => { data_type => 'float', size => [6,6], default_value => 0 },
    age                         => { data_type => 'int', size => 11, is_nullable => 0 },
    times_captured              => { data_type => 'int', size => 11, default_value => 0 },
    times_turned                => { data_type => 'int', size => 11, default_value => 0 },
    seeds_planted               => { data_type => 'int', size => 11, default_value => 0 },
    spies_killed                => { data_type => 'int', size => 11, default_value => 0 },
    spies_captured              => { data_type => 'int', size => 11, default_value => 0 },
    spies_turned                => { data_type => 'int', size => 11, default_value => 0 },
    things_destroyed            => { data_type => 'int', size => 11, default_value => 0 },
    things_stolen               => { data_type => 'int', size => 11, default_value => 0 },
    dirtiest                    => { data_type => 'int', size => 11, default_value => 0 },
    dirtiest_rank               => { data_type => 'int', size => 11, is_nullable => 0 },
    dirtiest_delta              => { data_type => 'int', size => 11, default_value => 0 },
);

after 'sqlt_deploy_hook' => sub {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_level_rank', fields => ['level_rank']);
    $sqlt_table->add_index(name => 'idx_success_rate_rank', fields => ['success_rate_rank']);
    $sqlt_table->add_index(name => 'idx_dirtiest_rank', fields => ['dirtiest_rank']);
    $sqlt_table->add_index(name => 'idx_planet_id', fields => ['planet_id']);
    $sqlt_table->add_index(name => 'idx_planet_name', fields => ['planet_name']);
    $sqlt_table->add_index(name => 'idx_spy_id', fields => ['spy_id']);
    $sqlt_table->add_index(name => 'idx_spy_name', fields => ['spy_name']);
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
