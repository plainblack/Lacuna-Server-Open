package Lacuna::DB::Result::Proposition::RenameAsteroid;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Proposition';

before pass => sub {
    my ($self) = @_;
    my $alliance = $self->alliance;
    my $bodies = Lacuna->db->resultset('Map::Body');
    my $asteroid = $bodies->find($self->scratch->{asteroid_id});
    my $name = $self->scratch->{name};
    if ($bodies->search({name=>$name, id=>{'!='=>$asteroid->id}})->count) {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the name *'.$name.'* had already taken, effectively nullifying the vote.');
    }
    elsif (not $asteroid->star->is_seized($self->alliance_id)) {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the asteroid was no longer under the jurisdiction of this alliance, effectively nullifying the vote.');
    }
    else {
        $asteroid->name($name);
        $asteroid->update;
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
