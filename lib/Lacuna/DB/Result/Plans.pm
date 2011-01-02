package Lacuna::DB::Result::Plans;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);
use DateTime;

__PACKAGE__->table('plans');
__PACKAGE__->add_columns(
    body_id                 => { data_type => 'int', size => 11, is_nullable => 0 },
    class                   => { data_type => 'varchar', size => 255, is_nullable => 0 },
    level                   => { data_type => 'tinyint', is_nullable => 0 },
    extra_build_level       => { data_type => 'tinyint', is_nullable => 1, default_value => 0 },
);

sub level_formatted {
    my $self = shift;
    my $level = $self->level;
    if ($self->extra_build_level) {
        $level .= '+'.$self->extra_build_level;
    }
    return $level;
}

__PACKAGE__->belongs_to('body', 'Lacuna::DB::Result::Map::Body', 'body_id');

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
