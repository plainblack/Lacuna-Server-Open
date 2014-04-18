package Lacuna::DB::Result::Map::Body;

use Moose;
use utf8;
use List::Util qw(max sum);
use Scalar::Util qw(weaken);

no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map';

__PACKAGE__->load_components('DynamicSubclass');
__PACKAGE__->table('body');
__PACKAGE__->add_columns(
    star_id                         => { data_type => 'int', is_nullable => 0 },
    name                            => { data_type => 'varchar', size => 255 },
    alliance_id                     => { data_type => 'int', is_nullable => 1 },
    class                           => { data_type => 'varchar', size => 255, is_nullable => 0 },
    empire_id                       => { data_type => 'int', is_nullable => 1 },
);

__PACKAGE__->belongs_to(    'star',         'Lacuna::DB::Result::Map::Star',    'star_id');
__PACKAGE__->belongs_to(    'alliance',     'Lacuna::DB::Result::Alliance',     'alliance_id',  { join_type => 'left', on_delete => 'set null' });
__PACKAGE__->belongs_to(    'empire',       'Lacuna::DB::Result::Empire',       'empire_id',    { join_type => 'left', on_delete => 'set null' });
__PACKAGE__->has_many(      '_buildings',   'Lacuna::DB::Result::Building',     'body_id');


{
    local *ensure_class_loaded = sub {}; # graham's crazy fix for circular dependency, may break if DynamicSubclass gets upgraded
    __PACKAGE__->typecast_map(class => {
        'Lacuna::DB::Result::Map::Body::Planet::Station' => 'Lacuna::DB::Result::Map::Body::Planet::Station',
    });
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

