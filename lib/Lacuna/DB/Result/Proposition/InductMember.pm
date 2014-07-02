package Lacuna::DB::Result::Proposition::InductMember;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Proposition';

before pass => sub {
    my ($self) = @_;

    my $invite_empire = Lacuna->db->resultset('Empire')->find($self->scratch->{invite_id});
    if (defined $invite_empire) {
        my $alliance = $self->alliance;
        my $count = $alliance->members->count;
        $count += $alliance->invites->count;

        my $empire = Lacuna->db->resultset('Empire')->find($self->proposed_by_id);
        my $building = Lacuna->db->resultset('Building')->find($self->scratch->{building_id});

        my $leader_emp = $building->body->empire;
        my $leader_planets = $leader_emp->planets;
        my @planet_ids;
        while ( my $planet = $leader_planets->next ) {
            push @planet_ids, $planet->id;
        }
        my $embassy = Lacuna->db->resultset('Building')->search(
            { body_id => { in => \@planet_ids }, class => 'Lacuna::DB::Result::Building::Embassy' },
            { order_by => { -desc => 'level' } }
        )->single;
        my $max_members = ( $building->level >= $embassy->level ) ? 2 * $building->level : 2 * $embassy->level;

        if ($count < $max_members ) {
            my $can = eval{$alliance->send_invite($invite_empire, $self->scratch->{message})};
            unless ($can) {
                $self->pass_extra_message('Empire has already accepted an invite, effectively wasting Parliaments time.');
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
