package Lacuna::DB::Result::Building;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';


__PACKAGE__->table('building');
__PACKAGE__->add_columns(
    body_id         => { data_type => 'int', size => 11, is_nullable => 0 },
    level           => { data_type => 'int', size => 11, default_value => 0 },
    class           => { data_type => 'varchar', size => 255, is_nullable => 0 },
    efficiency      => { data_type => 'int', default_value => 100, is_nullable => 0 },
);

__PACKAGE__->belongs_to('body', 'Lacuna::DB::Result::Map::Body', 'body_id');

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
