package Lacuna::DB::Result::Proposition::RepealLaw;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Proposition';

before pass => sub {
    my ($self) = @_;
    my $law = Lacuna->db->resultset('Law')->find($self->scratch->{law_id});
    if (defined $law) {
        $law->delete;
    }
    else {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the law was already repealed, effectively nullifying the vote.');
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
