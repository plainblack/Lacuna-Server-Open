package Lacuna::DB::Result::Proposition::BHGNeutralized;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Proposition';

before pass => sub {
    my ($self) = @_;
    my $law = Lacuna->db->resultset('Law')->new({
        name        => $self->name,
        description => $self->description,
        type        => 'BHGNeutralized',
        station_id  => $self->station_id,
    })->insert;
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
