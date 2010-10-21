package Lacuna::DB::Result::AllianceInvite;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);
use DateTime;

__PACKAGE__->table('alliance_invite');
__PACKAGE__->add_columns(
    alliance_id             => { data_type => 'int', is_nullable => 0 },
    empire_id               => { data_type => 'int', is_nullable => 0 },
    date_created            => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
);

__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Result::Empire', 'empire_id');
__PACKAGE__->belongs_to('alliance', 'Lacuna::DB::Result::Alliance', 'alliance_id');

sub date_created_formatted {
    my ($self) = @_;
    return format_date($self->date_created);
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
