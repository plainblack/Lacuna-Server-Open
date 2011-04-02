package Lacuna::DB::Result::Propositions::InductMember;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Propositions';

before pass => sub {
    my ($self) = @_;
    my $station = $self->station;
    my $alliance = $station->alliance;
    my $invite_empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($self->scratch->{empire_id});
    if (defined $invite_empire) {
        my $count = $alliance->members->count;
        $count += $alliance->invites->count;
        if ($count < $self->max_members ) {
            $alliance->send_invite($invite_empire, $self->scratch->{message});
        }
        else {
            $self->pass_extra_message('Unfortunately, by the time the proposition passed, the alliance had reached maximum membership, effectively nullifying the vote.');
        }
    }
    else {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the empire of the proposed new member no longer existed, effectively nullifying the vote.');
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
