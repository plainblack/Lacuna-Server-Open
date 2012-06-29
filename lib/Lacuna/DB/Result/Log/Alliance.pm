package Lacuna::DB::Result::Log::Alliance;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Log';
use Lacuna::Util;

__PACKAGE__->table('alliance_log');
__PACKAGE__->add_columns(
    alliance_id                 => { data_type => 'int', is_nullable => 0 },
    alliance_name               => { data_type => 'varchar', size => 30, is_nullable => 0 },
    member_count                => { data_type => 'int', is_nullable => 0 },
    space_station_count         => { data_type => 'int', is_nullable => 0 },
    space_station_count_rank    => { data_type => 'int', is_nullable => 0 },
    influence                   => { data_type => 'int', is_nullable => 0 },
    influence_rank              => { data_type => 'int', is_nullable => 0 },
    colony_count                => { data_type => 'int', is_nullable => 0 },
    population                  => { data_type => 'bigint', is_nullable => 0 },
    population_rank             => { data_type => 'int', is_nullable => 0 },
    average_empire_size         => { data_type => 'bigint', is_nullable => 0 },
    average_empire_size_rank    => { data_type => 'int', is_nullable => 0 },
    average_university_level    => { data_type => 'float', size =>[5,2], is_nullable => 0 },
    building_count              => { data_type => 'int', is_nullable => 0 },
    average_building_level      => { data_type => 'float', size =>[5,2], is_nullable => 0 },
    spy_count                   => { data_type => 'int', size => 11, is_nullable => 0 },
    offense_success_rate        => { data_type => 'float', size => [6,6], is_nullable => 0 },
    offense_success_rate_rank   => { data_type => 'int', size => 11, is_nullable => 0 },
    defense_success_rate        => { data_type => 'float', size => [6,6], is_nullable => 0 },
    defense_success_rate_rank   => { data_type => 'int', size => 11, is_nullable => 0 },
    dirtiest                    => { data_type => 'int', size => 11, default_value => 0 },
    dirtiest_rank               => { data_type => 'int', size => 11, default_value => 0 },
);

after 'sqlt_deploy_hook' => sub {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_average_empire_size_rank', fields => ['average_empire_size_rank']);
    $sqlt_table->add_index(name => 'idx_offense_success_rate_rank', fields => ['offense_success_rate_rank']);
    $sqlt_table->add_index(name => 'idx_defense_success_rate_rank', fields => ['defense_success_rate_rank']);
    $sqlt_table->add_index(name => 'idx_dirtiest_rank', fields => ['dirtiest_rank']);
    $sqlt_table->add_index(name => 'idx_population_rank', fields => ['population_rank']);
    $sqlt_table->add_index(name => 'idx_influence_rank', fields => ['influence_rank']);
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
