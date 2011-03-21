package Lacuna::DB::Result::Propositions::DemolishBuilding;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Propositions';

before pass => sub {
    my ($self) = @_;
    my $station = $self->station;
    my $building = $station->buildings->find($self->scratch->{building_id});
    if (defined $building) {
        $building->demolish;
    }
    else {
        $self->pass_extra_message('Unfortunately by the time the proposition passed, the building had already been demolished, effectively nullifying the vote.');
    }
};

before fail => sub {
    my ($self) = @_;
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
