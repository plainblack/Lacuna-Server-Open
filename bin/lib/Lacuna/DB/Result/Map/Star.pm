package Lacuna::DB::Result::Map::Star;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map';

__PACKAGE__->table('star');
__PACKAGE__->add_columns(
    color                   => { data_type => 'varchar', size => 7, is_nullable => 0 },
    station_id              => { data_type => 'int', is_nullable => 1 },
    alliance_id             => { data_type => 'int', is_nullable => 1 },
    seize_strength          => { data_type => 'int', is_nullable => 0, default => 0 },
);

__PACKAGE__->belongs_to('station', 'Lacuna::DB::Result::Map::Body', 'station_id', { join_type => 'left', on_delete => 'set null' });
__PACKAGE__->belongs_to('alliance', 'Lacuna::DB::Result::Alliance', 'alliance_id', { join_type => 'left', on_delete => 'set null' });
no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
