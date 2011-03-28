package Lacuna::DB::Result::Propositions::RepealLaw;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Propositions';

before pass => sub {
    my ($self) = @_;
    my $law = Lacuna->db->resultset('Lacuna::DB::Result::Laws')->find($self->scratch->{law_id});
    if (defined $law) {
        $law->delete;
    }
    else {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the law was already repealed, effectively nullifying the vote.');
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
