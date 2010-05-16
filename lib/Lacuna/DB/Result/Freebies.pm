package Lacuna::DB::Result::Freebies;

use Moose;
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);
use DateTime;

__PACKAGE__->table('freebies');
__PACKAGE__->add_columns(
    body_id                 => { data_type => 'int', size => 11, is_nullable => 0 },
    class                   => { data_type => 'char', size => 255, is_nullable => 0 },
    level                   => { data_type => 'int', size => 3, is_nullable => 0 },
    extra_build_level       => { data_type => 'int', size => 3, is_nullable => 1, default => 0 },
);

__PACKAGE__->belongs_to('body', 'Lacuna::DB::Result::Map::Body', 'body_id');

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
