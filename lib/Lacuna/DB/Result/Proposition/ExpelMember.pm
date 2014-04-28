package Lacuna::DB::Result::Proposition::ExpelMember;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Proposition';

before pass => sub {
    my ($self) = @_;
    my $station = $self->station;
    my $alliance = $station->alliance;
    my $empire_to_remove = Lacuna->db->resultset('Empire')->find($self->scratch->{empire_id});
    if (defined $empire_to_remove) {
        if ($empire_to_remove->alliance_id == $alliance->id) {
            $alliance->remove_member($empire_to_remove);
            $empire_to_remove->send_predefined_message(
                from        => $alliance->leader,
                tags        => ['Alliance','Correspondence'],
                filename    => 'alliance_expelled.txt',
                params      => [$alliance->id, $alliance->name, $self->scratch->{message}, $alliance->name],
            );
        }
        else {
            $self->pass_extra_message('Unfortunately, by the time the proposition passed, the empire to expel was no longer a member of the alliance, effectively nullifying the vote.');
        }
    }
    else {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the empire to expel no longer existed, effectively nullifying the vote.');
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
