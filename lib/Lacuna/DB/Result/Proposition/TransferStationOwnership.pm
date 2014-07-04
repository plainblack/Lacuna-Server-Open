package Lacuna::DB::Result::Proposition::TransferStationOwnership;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Proposition';

before pass => sub {
    my ($self) = @_;
    my $station = $self->station;
    my $to_empire = Lacuna->db->resultset('Empire')->find($self->scratch->{empire_id});
    if (defined $to_empire) {
        if ($to_empire->alliance_id == $station->alliance_id) {
            $station->empire_id($to_empire->id);
            $station->update;
        }
        else {
            $self->pass_extra_message('Unfortunately, by the time the proposition passed, the receiving empire was no longer a member of the alliance, effectively nullifying the vote.');
        }
    }
    else {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the receiving empire no longer existed, effectively nullifying the vote.');
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
