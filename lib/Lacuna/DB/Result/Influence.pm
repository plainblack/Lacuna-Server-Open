package Lacuna::DB::Result::Influence;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';

__PACKAGE__->table('influence');
__PACKAGE__->add_columns(
    station_id              => { data_type => 'int', is_nullable => 0 },
    star_id                 => { data_type => 'int', is_nullable => 0 },
    alliance_id             => { data_type => 'int', is_nullable => 0 },
    influence               => { data_type => 'int', is_nullable => 0, default => 0 },
);

__PACKAGE__->belongs_to('station',  'Lacuna::DB::Result::Map::Body',    'station_id');
__PACKAGE__->belongs_to('star',     'Lacuna::DB::Result::Map::Star',    'star_id');
__PACKAGE__->belongs_to('alliance', 'Lacuna::DB::Result::Alliance',     'alliance_id');

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
