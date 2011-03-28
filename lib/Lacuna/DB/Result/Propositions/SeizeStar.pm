package Lacuna::DB::Result::Propositions::SeizeStar;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Propositions';

before pass => sub {
    my ($self) = @_;
    my $station = $self->station;
    my $star = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->find($self->scratch->{star_id});
    if (!$star->station_id) {
        my $law = Lacuna->db->resultset('Lacuna::DB::Result::Laws')->new({
            name        => $self->name,
            description => $self->description,
            type        => 'Jurisdiction',
            station_id  => $self->station_id,
            star_id     => $star->id,
        });
        $law->star($star);
        $law->insert;
    }
    else {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the star was already controlled by another station, effectively nullifying the vote.');
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
