package Lacuna::DB::Result::Log::Empire;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Log::WithEmpire';
use Lacuna::Util;

__PACKAGE__->table('empire_log');
__PACKAGE__->add_columns(
    colony_count                => { data_type => 'tinyint', is_nullable => 0 },
    colony_count_delta          => { data_type => 'tinyint', is_nullable => 0 },
    population                  => { data_type => 'int', size => 11, is_nullable => 0 },
    population_delta            => { data_type => 'int', size => 11, is_nullable => 0 },
    empire_size                 => { data_type => 'bigint', size => 11, is_nullable => 0 },
    empire_size_delta           => { data_type => 'int', size => 11, is_nullable => 0 },
    empire_size_rank            => { data_type => 'int', size => 11, is_nullable => 0 },
    building_count              => { data_type => 'smallint', is_nullable => 0 },
    university_level            => { data_type => 'tinyint', is_nullable => 0 },
    university_level_rank       => { data_type => 'tinyint', is_nullable => 0 },
    average_building_level      => { data_type => 'float', size =>[5,2] , is_nullable => 0 },
    highest_building_level      => { data_type => 'tinyint', size => 3, is_nullable => 0 },
    food_hour                   => { data_type => 'int', size => 11, is_nullable => 0 },
    energy_hour                 => { data_type => 'int', size => 11, is_nullable => 0 },
    waste_hour                  => { data_type => 'int', size => 11, is_nullable => 0 },
    ore_hour                    => { data_type => 'int', size => 11, is_nullable => 0 },
    water_hour                  => { data_type => 'int', size => 11, is_nullable => 0 },
    happiness_hour              => { data_type => 'int', size => 11, is_nullable => 0 },
    spy_count                   => { data_type => 'int', size => 11, is_nullable => 0 },
    offense_success_rate        => { data_type => 'float', size => [6,6], is_nullable => 0 },
    offense_success_rate_rank   => { data_type => 'int', size => 11, is_nullable => 0 },
    offense_success_rate_delta  => { data_type => 'float', size => [6,6], default_value => 0 },
    defense_success_rate        => { data_type => 'float', size => [6,6], is_nullable => 0 },
    defense_success_rate_rank   => { data_type => 'int', size => 11, is_nullable => 0 },
    defense_success_rate_delta  => { data_type => 'float', size => [6,6], default_value => 0 },
    dirtiest                    => { data_type => 'int', size => 11, default_value => 0 },
    dirtiest_rank               => { data_type => 'int', size => 11, default_value => 0 },
    dirtiest_delta              => { data_type => 'int', size => 11, default_value => 0 },
    alliance_id                 => { data_type => 'int', is_nullable => 1 },
    alliance_name               => { data_type => 'varchar', size => 30, is_nullable => 1 },
    space_station_count         => { data_type => 'int', size => 11, default_value => 0 },
    influence                   => { data_type => 'int', size => 11, default_value => 0 },
);

after 'sqlt_deploy_hook' => sub {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_empire_size_rank', fields => ['empire_size_rank']);
    $sqlt_table->add_index(name => 'idx_university_level_rank', fields => ['university_level_rank']);
    $sqlt_table->add_index(name => 'idx_offense_success_rate_rank', fields => ['offense_success_rate_rank']);
    $sqlt_table->add_index(name => 'idx_defense_success_rate_rank', fields => ['defense_success_rate_rank']);
    $sqlt_table->add_index(name => 'idx_dirtiest_rank', fields => ['dirtiest_rank']);
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
