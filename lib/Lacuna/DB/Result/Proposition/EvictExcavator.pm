package Lacuna::DB::Result::Proposition::EvictExcavator;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Proposition';

before pass => sub {
    my ($self) = @_;
    my $excav = Lacuna->db->resultset('Excavators')->find($self->scratch->{excav_id});   
    my $bodies = Lacuna->db->resultset('Map::Body');
    my $body = $bodies->find($self->scratch->{excav_id});
    my $name = $self->scratch->{name};
    if (! defined $excav) {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the excavator had already been destroyed, effectively nullifying the vote.');
    }
    elsif (not $excav->body->star->is_seized($self->alliance_id)) {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the body was no longer under the jurisdiction of this alliance, effectively nullifying the vote.');
    }
    else {
        $excav->planet->empire->send_predefined_message(
            filename    => 'parliament_evict_excavator.txt',
            params      => [$self->alliance->name, $excav->body->x, $excav->body->y, $excav->body->name],
            from        => $self->alliance->leader,
            tags        => ['Parliament','Correspondence'],
        );
        $excav->planet->get_building_of_class('Lacuna::DB::Result::Building::Archaeology')->remove_excavator($excav);
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
