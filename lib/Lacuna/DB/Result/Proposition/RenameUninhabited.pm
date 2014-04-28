package Lacuna::DB::Result::Proposition::RenameUninhabited;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Proposition';

before pass => sub {
    my ($self) = @_;
    my $station = $self->station;
    my $bodies = Lacuna->db->resultset('Map::Body');
    my $planet = $bodies->find($self->scratch->{planet_id});
    my $name = $self->scratch->{name};
    if ($bodies->search({name=>$name, 'id'=>{'!='=>$planet->id}})->count) {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the name *'.$name.'* had already taken, effectively nullifying the vote.');
    }
    elsif ($planet->star->station_id != $station->id) {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the planet was no longer under the jurisdiction of this station, effectively nullifying the vote.');
    }
    elsif ($planet->empire_id) {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the planet had been inhabited.');
    }
    else {
        $planet->name($name);
        $planet->update;
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
