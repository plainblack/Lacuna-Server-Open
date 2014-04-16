package Lacuna::DB::Result::Map::Body;

use Moose;
use utf8;
use List::Util qw(max sum);
use Scalar::Util qw(weaken);

no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map';

__PACKAGE__->table('body');
__PACKAGE__->add_columns(
    star_id                         => { data_type => 'int', is_nullable => 0 },
    alliance_id                     => { data_type => 'int', is_nullable => 1 },
    class                           => { data_type => 'varchar', size => 255, is_nullable => 0 },
    empire_id                       => { data_type => 'int', is_nullable => 1 },
);

__PACKAGE__->belongs_to('star', 'Lacuna::DB::Result::Map::Star', 'star_id');
__PACKAGE__->belongs_to('alliance', 'Lacuna::DB::Result::Alliance', 'alliance_id', { on_delete => 'set null' });
__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Result::Empire', 'empire_id');

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
