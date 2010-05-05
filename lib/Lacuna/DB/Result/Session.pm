package Lacuna::DB::Result::Session;

use Moose;
extends 'Lacuna::DB::Result';
use DateTime;

__PACKAGE__->table('session');
__PACKAGE__->add_columns(
    empire_id       => { isa => 'Str' },
    date_created    => { data_type => 'datetime', is_nullable => 0, default_value => DateTime->now },
    expires         => { data_type => 'datetime', is_nullable => 0, default_value => DateTime->now },
);

__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Result::Empire', 'empire_id');

sub extend {
    my $self = shift;
    $self->expires(DateTime->now->add(hours=>2));
    $self->put;
}

sub has_expired {
    my $self = shift;
    return (DateTime->now > $self->expires);
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
