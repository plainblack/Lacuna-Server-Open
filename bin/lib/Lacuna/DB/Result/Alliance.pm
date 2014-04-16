package Lacuna::DB::Result::Alliance;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';

__PACKAGE__->table('alliance');
__PACKAGE__->add_columns(
    name                    => { data_type => 'varchar', size => 30, is_nullable => 0 },
    leader_id               => { data_type => 'int', size => 11, is_nullable => 1 },
); 

__PACKAGE__->belongs_to('leader', 'Lacuna::DB::Result::Empire', 'leader_id', { on_delete => 'set null' });
__PACKAGE__->has_many('members', 'Lacuna::DB::Result::Empire', 'alliance_id');
__PACKAGE__->has_many('stations', 'Lacuna::DB::Result::Map::Body', 'alliance_id');


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
