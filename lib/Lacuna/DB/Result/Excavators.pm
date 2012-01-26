package Lacuna::DB::Result::Excavators;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';

__PACKAGE__->table('excavators');
__PACKAGE__->add_columns(
    planet_id   => { data_type => 'int', size => 11, is_nullable => 0 },
    body_id     => { data_type => 'int', size => 11, is_nullable => 0 },
    empire_id   => { data_type => 'int', size => 11, is_nullable => 0 },
);

__PACKAGE__->belongs_to('body', 'Lacuna::DB::Result::Map::Body', 'body_id');
__PACKAGE__->belongs_to('planet', 'Lacuna::DB::Result::Map::Body', 'planet_id');

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
