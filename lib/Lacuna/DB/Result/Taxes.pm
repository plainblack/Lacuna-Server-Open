package Lacuna::DB::Result::Taxes;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);
use DateTime;

__PACKAGE__->table('taxes');
__PACKAGE__->add_columns(
    empire_id               => { data_type => 'int', size => 11, is_nullable => 0 },
    station_id              => { data_type => 'int', size => 11, is_nullable => 0 },
    paid_6                  => { data_type => 'int', size => 11, is_nullable => 0 },
    paid_5                  => { data_type => 'int', size => 11, is_nullable => 0 },
    paid_4                  => { data_type => 'int', size => 11, is_nullable => 0 },
    paid_3                  => { data_type => 'int', size => 11, is_nullable => 0 },
    paid_2                  => { data_type => 'int', size => 11, is_nullable => 0 },
    paid_1                  => { data_type => 'int', size => 11, is_nullable => 0 },
    paid_0                  => { data_type => 'int', size => 11, is_nullable => 0 },
);

sub get_status {
    my $self = shift;
    return {
        id                  => $self->empire_id,
        name                => $self->empire->name,
        paid                => [ $self->paid_6, $self->paid_5, $self->paid_4, $self->paid_3, $self->paid_2, $self->paid_1, $self->paid_0 ],
        total               => $self->paid_6 + $self->paid_5 + $self->paid_4 + $self->paid_3 + $self->paid_2 + $self->paid_1 + $self->paid_0,
    };
}

__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Result::Empire', 'empire_id');
__PACKAGE__->belongs_to('station', 'Lacuna::DB::Result::Map::Body', 'station_id');

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
