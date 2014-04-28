package Lacuna::DB::Result::Proposition::ElectNewLeader;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Proposition';

before pass => sub {
    my ($self) = @_;
    my $station = $self->station;
    my $alliance = $station->alliance;
    my $new_leader = Lacuna->db->resultset('Empire')->find($self->scratch->{empire_id});
    if (defined $new_leader) {
        if ($new_leader->alliance_id == $alliance->id) {
            $alliance->leader_id($new_leader->id);
            $alliance->update;
        }
        else {
            $self->pass_extra_message('Unfortunately, by the time the proposition passed, the elected empire was no longer a member of the alliance, effectively nullifying the vote.');
        }
    }
    else {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the elected empire no longer existed, effectively nullifying the vote.');
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
