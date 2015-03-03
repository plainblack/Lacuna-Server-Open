package Lacuna::DB::Result::Propositions::InductMember;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Propositions';
use List::Util qw(max);

before pass => sub {
    my ($self) = @_;

    my $station = $self->station;
    my $invite_empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($self->scratch->{invite_id});
    if (defined $invite_empire) {
        my $alliance = $station->alliance;
        my $count = $alliance->members->count;
        $count += $alliance->invites->count;

        my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($self->proposed_by_id);
        my $building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->find($self->scratch->{building_id});

        my $leader_emp = $building->body->empire;
        my $embassy    = $leader_emp->highest_embassy;
        my $max_members = max($embassy->max_members(), $embassy->max_members($building->effective_level));

        if ($count < $max_members ) {
            my $can = eval{$alliance->send_invite($invite_empire, $self->scratch->{message})};
            unless ($can) {
                $self->pass_extra_message(q[Empire has already accepted an invite, effectively wasting Parliaments' time.]);
            }
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
