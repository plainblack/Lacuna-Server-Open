package Lacuna::DB::Result::Log::Colony;

use Moose;
extends 'Lacuna::DB::Result::Log';
use Lacuna::Util;

__PACKAGE__->table('colony_log');
__PACKAGE__->add_columns(
    planet_id                   => { data_type => 'int', size => 11, is_nullable => 0 },
    planet_name                 => { data_type => 'char', size => 30, is_nullable => 0 },
    population                  => { data_type => 'int', size => 11, is_nullable => 0 },
    population_delta            => { data_type => 'int', size => 11, is_nullable => 0 },
    building_count              => { data_type => 'int', size => 3, is_nullable => 0 },
    average_building_level      => { data_type => 'float', size =>[3,2] , is_nullable => 0 },
    highest_building_level      => { data_type => 'int', size => 3, is_nullable => 0 },
    food_hour                   => { data_type => 'int', size => 11, is_nullable => 0 },
    energy_hour                 => { data_type => 'int', size => 11, is_nullable => 0 },
    waste_hour                  => { data_type => 'int', size => 11, is_nullable => 0 },
    ore_hour                    => { data_type => 'int', size => 11, is_nullable => 0 },
    water_hour                  => { data_type => 'int', size => 11, is_nullable => 0 },
    spy_count                   => { data_type => 'int', size => 11, is_nullable => 0 },
    average_spy_success_rate    => { data_type => 'float', size => [6,6], default_value => 0 },
    offense_success_rate        => { data_type => 'float', size => [6,6], default_value => 0 },
    offense_success_rate_delta  => { data_type => 'float', size => [6,6], default_value => 0 },
    defense_success_rate        => { data_type => 'float', size => [6,6], default_value => 0 },
    defense_success_rate_delta  => { data_type => 'float', size => [6,6], default_value => 0 },
    dirtiest                    => { data_type => 'int', size => 11, default_value => 0 },
    dirtiest_delta              => { data_type => 'int', size => 11, default_value => 0 },
);

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
