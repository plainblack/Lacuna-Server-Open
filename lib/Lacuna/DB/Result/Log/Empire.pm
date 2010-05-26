package Lacuna::DB::Result::Log::Empire;

use Moose;
extends 'Lacuna::DB::Result::Log';
use Lacuna::Util;

__PACKAGE__->table('empire_log');
__PACKAGE__->add_columns(
    colony_count            => { data_type => 'int', size => 3, is_nullable => 0 },
    population              => { data_type => 'int', size => 11, is_nullable => 0 },
    building_count          => { data_type => 'int', size => 3, is_nullable => 0 },
    university_level        => { data_type => 'int', size => 3, is_nullable => 0 },
    average_building_level  => { data_type => 'float', size =>[3,2] , is_nullable => 0 },
    highest_building_level  => { data_type => 'int', size => 3, is_nullable => 0 },
    lowest_building_level   => { data_type => 'int', size => 3, is_nullable => 0 },
    food_hour               => { data_type => 'int', size => 11, is_nullable => 0 },
    energy_hour             => { data_type => 'int', size => 11, is_nullable => 0 },
    waste_hour              => { data_type => 'int', size => 11, is_nullable => 0 },
    ore_hour                => { data_type => 'int', size => 11, is_nullable => 0 },
    water_hour              => { data_type => 'int', size => 11, is_nullable => 0 },
);

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
