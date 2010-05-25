package Lacuna::DB::Result::Log;

use Moose;
extends 'Lacuna::DB::Result';
use Lacuna::Util;

__PACKAGE__->table('noexist_log');
__PACKAGE__->add_columns(
    date_stamp              => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    empire_id               => { data_type => 'int', size => 11, is_nullable => 0 },
    empire_name             => { data_type => 'char', size => 30, is_nullable => 0 },
);


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
