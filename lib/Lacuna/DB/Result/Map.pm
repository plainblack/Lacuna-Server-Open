package Lacuna::DB::Result::Map;

use Moose;
extends 'Lacuna::DB::Result';
use Lacuna::Util;

__PACKAGE__->add_columns(
    name                    => { data_type => 'char', size => 30, is_nullable => 0 },
    x                       => { data_type => 'int', size => 11, default_value => 0 },
    y                       => { data_type => 'int', size => 11, default_value => 0 },
    zone                    => { data_type => 'char', size => 16, is_nullable => 0 },
);

with 'Lacuna::Role::Zoned';

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
