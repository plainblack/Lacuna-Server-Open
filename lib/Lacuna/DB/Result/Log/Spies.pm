package Lacuna::DB::Result::Log::Spies;

use Moose;
extends 'Lacuna::DB::Result::Log';
use Lacuna::Util;

__PACKAGE__->table('spy_log');
__PACKAGE__->add_columns(
    spy_name                => { data_type => 'char', size => 30, is_nullable => 0 },
    spy_id                  => { data_type => 'int', size => 11, is_nullable => 0 },
    planet_name             => { data_type => 'char', size => 30, is_nullable => 0 },
    planet_id               => { data_type => 'int', size => 11, is_nullable => 0 },
    level                   => { data_type => 'int', size => 11, is_nullable => 0 },
    level_delta             => { data_type => 'int', size => 11, default_value => 0 },
    success_rate            => { data_type => 'float', size => [11,2], is_nullable => 0 },
    success_rate_delta      => { data_type => 'float', size => [11,2], default_value => 0 },
    age                     => { data_type => 'int', size => 11, is_nullable => 0 },
    times_captured          => { data_type => 'int', size => 11, default_value => 0 },
    times_turned            => { data_type => 'int', size => 11, default_value => 0 },
    seeds_planted           => { data_type => 'int', size => 11, default_value => 0 },
    spies_killed            => { data_type => 'int', size => 11, default_value => 0 },
    spies_captured          => { data_type => 'int', size => 11, default_value => 0 },
    spies_turned            => { data_type => 'int', size => 11, default_value => 0 },
    things_destroyed        => { data_type => 'int', size => 11, default_value => 0 },
    things_stolen           => { data_type => 'int', size => 11, default_value => 0 },
);

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
