package Lacuna::DB::Result::Empire;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';

__PACKAGE__->table('empire');
__PACKAGE__->add_columns(
    name                    => { data_type => 'varchar', size => 30, is_nullable => 0 },
    alliance_id             => { data_type => 'int', is_nullable => 1 },
);

__PACKAGE__->belongs_to('alliance',         'Lacuna::DB::Result::Alliance',     'alliance_id', { on_delete => 'set null' });

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
