package Lacuna::DB::Result::Probes;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);
use DateTime;

__PACKAGE__->table('probes');
__PACKAGE__->add_columns(
    empire_id               => { data_type => 'int', is_nullable => 0 },
    star_id                 => { data_type => 'int', is_nullable => 0 },
    body_id                 => { data_type => 'int', is_nullable => 0 },
    alliance_id             => { data_type => 'int', is_nullable => 1 },
    virtual                 => { data_type => 'int', is_nullable => 1, default => 0 },
);

__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Result::Empire', 'empire_id');
__PACKAGE__->belongs_to('star', 'Lacuna::DB::Result::Map::Star', 'star_id');
__PACKAGE__->belongs_to('body', 'Lacuna::DB::Result::Map::Body', 'body_id');
__PACKAGE__->belongs_to('alliance', 'Lacuna::DB::Result::Alliance', 'alliance_id');


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
