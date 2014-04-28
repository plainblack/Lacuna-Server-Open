package Lacuna::DB::Result::Proposition::RenameStation;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Proposition';

before pass => sub {
    my ($self) = @_;
    my $station = $self->station;
    my $name = $self->scratch->{name};
    if (Lacuna->db->resultset('Map::Body')->search({name=>$name, 'id'=>{'!='=>$station->id}})->count) {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the name *'.$name.'* had already taken, effectively nullifying the vote.');
    }
    else {
        $station->name($name);
        $station->update;
    }
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
