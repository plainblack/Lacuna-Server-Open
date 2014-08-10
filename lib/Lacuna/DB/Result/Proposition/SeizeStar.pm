package Lacuna::DB::Result::Proposition::SeizeStar;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Proposition';

before pass => sub {
    my ($self) = @_;
    my $alliance = $self->alliance;
    my $station = $self->station;
    my $star = Lacuna->db->resultset('Map::Star')->find($self->scratch->{star_id});
    if ($star->in_starter_zone) {
        $self->pass_extra_message('This star is in a starter zone and cannot be seized.');
    }
    elsif ($star->in_neutral_area) {
        $self->pass_extra_message('This star is in the neutral area and cannot be seized.');
    }
    elsif ($star->is_seized) {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the star was already controlled by another station, effectively nullifying the vote.');
    }
    else {
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
