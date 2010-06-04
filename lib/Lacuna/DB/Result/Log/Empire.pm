package Lacuna::DB::Result::Log::Empire;

use Moose;
extends 'Lacuna::DB::Result::Log';
use Lacuna::Util;

__PACKAGE__->table('empire_log');
__PACKAGE__->add_columns(
    colony_count                => { data_type => 'int', size => 3, is_nullable => 0 },
    colony_count_delta          => { data_type => 'int', size => 3, is_nullable => 0 },
    population                  => { data_type => 'int', size => 11, is_nullable => 0 },
    population_delta            => { data_type => 'int', size => 11, is_nullable => 0 },
    empire_size                 => { data_type => 'int', size => 11, is_nullable => 0 },
    empire_size_delta           => { data_type => 'int', size => 11, is_nullable => 0 },
    building_count              => { data_type => 'int', size => 3, is_nullable => 0 },
    university_level            => { data_type => 'int', size => 3, is_nullable => 0 },
    average_building_level      => { data_type => 'float', size =>[3,2] , is_nullable => 0 },
    highest_building_level      => { data_type => 'int', size => 3, is_nullable => 0 },
    food_hour                   => { data_type => 'int', size => 11, is_nullable => 0 },
    energy_hour                 => { data_type => 'int', size => 11, is_nullable => 0 },
    waste_hour                  => { data_type => 'int', size => 11, is_nullable => 0 },
    ore_hour                    => { data_type => 'int', size => 11, is_nullable => 0 },
    water_hour                  => { data_type => 'int', size => 11, is_nullable => 0 },
    spy_count                   => { data_type => 'int', size => 11, is_nullable => 0 },
    offense_success_rate        => { data_type => 'float', size => [6,6], is_nullable => 0 },
    offense_success_rate_delta  => { data_type => 'float', size => [6,6], default_value => 0 },
    defense_success_rate        => { data_type => 'float', size => [6,6], is_nullable => 0 },
    defense_success_rate_delta  => { data_type => 'float', size => [6,6], default_value => 0 },
    dirtiest                    => { data_type => 'int', size => 11, default_value => 0 },
    dirtiest_delta              => { data_type => 'int', size => 11, default_value => 0 },
);

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
