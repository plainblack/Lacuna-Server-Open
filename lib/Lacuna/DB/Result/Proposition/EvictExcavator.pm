package Lacuna::DB::Result::Proposition::EvictExcavator;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Proposition';

before pass => sub {
    my ($self) = @_;
    my $excav = Lacuna->db->resultset('Excavators')->find($self->scratch->{excav_id});   
    my $station = $self->station;
    my $bodies = Lacuna->db->resultset('Map::Body');
    my $body = $bodies->find($self->scratch->{excav_id});
    my $name = $self->scratch->{name};
    if (! defined $excav) {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the excavator had already been destroyed, effectively nullifying the vote.');
    }
    elsif ($self->station_id != $excav->body->star->station_id) {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the body was no longer under the jurisdiction of this station, effectively nullifying the vote.');
    }
    else {
        $excav->planet->empire->send_predefined_message(
            filename    => 'parliament_evict_excavator.txt',
            params      => [$station->alliance->name, $excav->body->x, $excav->body->y, $excav->body->name],
            from        => $station->alliance->leader,
            tags        => ['Parliament','Correspondence'],
        );
        $excav->planet->get_building_of_class('Lacuna::DB::Result::Building::Archaeology')->remove_excavator($excav);
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
