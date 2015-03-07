package Lacuna::DB::Result::Propositions::RenameStar;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Propositions';

before pass => sub {
    my ($self) = @_;
    my $station = $self->station;
    my $star = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->find($self->scratch->{star_id});
    my $name = $self->scratch->{name};
    if (!defined($star) or $star->station_id != $station->id) {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the star was no longer under the jurisdiction of this station, effectively nullifying the vote.');
    }
    elsif (Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->search({name=>$name, 'id'=>{'!='=>$star->id}})->count) {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the name *'.$name.'* had already been taken, effectively nullifying the vote.');
    }
    else {
        $star->name($name);
        $star->update;
    }
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
