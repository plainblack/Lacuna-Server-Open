package Lacuna::DB::Result::Propositions::EnactWrit;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Propositions';

before pass => sub {
    my ($self) = @_;
    my $law = Lacuna->db->resultset('Lacuna::DB::Result::Laws')->new({
        name        => $self->name,
        description => $self->description,
        type        => 'Writ',
    })->insert;
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
