package Lacuna::DB::Result::Propositions::SeizeStar;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Propositions';

before pass => sub {
    my ($self) = @_;
    my $station = $self->station;
    my $star = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->find($self->scratch->{star_id});
    if ($star->in_starter_zone) {
        $self->pass_extra_message('This star is in a starter zone and cannot be seized.');
    }
    elsif ($star->in_neutral_area) {
        $self->pass_extra_message('This star is in the neutral area and cannot be seized.');
    }
    elsif (!$star->station_id) {
        my $influence_remaining = $station->influence_remaining;
        if ( $influence_remaining >= 1 ) {
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
            $self->pass_extra_message('Unfortunately, by the time the proposition passed, the station lacked any spare influence, effectively nullifying the vote.');
        }
    }
    else {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the star was already controlled by another station, effectively nullifying the vote.');
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
