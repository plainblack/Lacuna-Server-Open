package Lacuna::DB::Result::Proposition::DemolishModule;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Proposition';

before pass => sub {
    my ($self) = @_;
    my $station = $self->station;
    my $building = $station->find_building($self->scratch->{building_id});
    if (defined $building) {
        $building->demolish;
    }
    else {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the module had already been demolished, effectively nullifying the vote.');
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
