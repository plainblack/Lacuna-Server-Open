package Lacuna::DB::Result::Glyphs;

use Moose;
extends 'Lacuna::DB::Result';

__PACKAGE__->table('plans');
__PACKAGE__->add_columns(
    body_id                 => { data_type => 'int', is_nullable => 0 },
    type                    => { data_type => 'varchar', size => 20, is_nullable => 0 },
);

__PACKAGE__->belongs_to('body', 'Lacuna::DB::Result::Map::Body', 'body_id');

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
