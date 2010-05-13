package Lacuna::DB::Result::MiningPlatforms;

use Moose;
extends 'Lacuna::DB::Result';

__PACKAGE__->table('probes');
__PACKAGE__->add_columns(
    ministry_id                     => { data_type => 'int', size => 11, is_nullable => 0 },
    planet_id                       => { data_type => 'int', size => 11, is_nullable => 0 },
    asteroid_id                     => { data_type => 'int', size => 11, is_nullable => 0 },
    rutile_hour                     => { data_type => 'int', size => 11, default_value => 0 },
    chromite_hour                   => { data_type => 'int', size => 11, default_value => 0 },
    chalcopyrite_hour               => { data_type => 'int', size => 11, default_value => 0 },
    galena_hour                     => { data_type => 'int', size => 11, default_value => 0 },
    gold_hour                       => { data_type => 'int', size => 11, default_value => 0 },
    uraninite_hour                  => { data_type => 'int', size => 11, default_value => 0 },
    bauxite_hour                    => { data_type => 'int', size => 11, default_value => 0 },
    goethite_hour                   => { data_type => 'int', size => 11, default_value => 0 },
    halite_hour                     => { data_type => 'int', size => 11, default_value => 0 },
    gypsum_hour                     => { data_type => 'int', size => 11, default_value => 0 },
    trona_hour                      => { data_type => 'int', size => 11, default_value => 0 },
    kerogen_hour                    => { data_type => 'int', size => 11, default_value => 0 },
    methane_hour                    => { data_type => 'int', size => 11, default_value => 0 },
    anthracite_hour                 => { data_type => 'int', size => 11, default_value => 0 },
    sulfur_hour                     => { data_type => 'int', size => 11, default_value => 0 },
    zircon_hour                     => { data_type => 'int', size => 11, default_value => 0 },
    monazite_hour                   => { data_type => 'int', size => 11, default_value => 0 },
    fluorite_hour                   => { data_type => 'int', size => 11, default_value => 0 },
    beryl_hour                      => { data_type => 'int', size => 11, default_value => 0 },
    magnetite_hour                  => { data_type => 'int', size => 11, default_value => 0 },
);

__PACKAGE__->belongs_to('ministry', 'Lacuna::DB::Result::Building', 'ministry_id');
__PACKAGE__->belongs_to('asteroid', 'Lacuna::DB::Result::Map::Body', 'asteroid_id');
__PACKAGE__->belongs_to('planet', 'Lacuna::DB::Result::Map::Body', 'planet_id');


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);