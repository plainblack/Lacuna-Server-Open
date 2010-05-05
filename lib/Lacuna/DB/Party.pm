package Lacuna::DB::Party;

use Moose;
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);
use DateTime;

__PACKAGE__->table('party');
__PACKAGE__->add_columns(
    park_id             => { data_type => 'int', size => 11, is_nullable => 0 },
    body_id                 => { data_type => 'int', size => 11, is_nullable => 0 },
    party_ends              => { data_type => 'datetime', is_nullable => 0, default_value => DateTime->now },
    happiness_from_party    => { isa => 'Int', default => 0 },
);

__PACKAGE__->belongs_to('park', 'Lacuna::DB::Building::Park', 'park_id');
__PACKAGE__->belongs_to('body', 'Lacuna::DB::Body::Planet', 'body_id');

sub party_seconds_remaining {
    my ($self) = @_;
    return to_seconds($self->party_ends - DateTime->now);
}

sub party_ends_formatted {
    my $self = shift;
    return format_date($self->party_ends);
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
