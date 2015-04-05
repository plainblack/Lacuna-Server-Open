package Lacuna::DB::Result::Propositions::BHGPassport;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Propositions';

before pass => sub {
    my ($self) = @_;
    my $law = Lacuna->db->resultset('Lacuna::DB::Result::Laws')->new({
        name        => $self->name,
        description => $self->description,
        scratch     => $self->scratch,
        type        => 'BHGPassport',
        station_id  => $self->station_id,
    })->insert;
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
