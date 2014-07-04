package Lacuna::DB::Result::Proposition::RepairModule;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Proposition';

before pass => sub {
    my ($self) = @_;
    my $station = $self->station;
    my $building = $station->find_building($self->scratch->{building_id});
    if (defined $building) {
        my $costs = $building->get_repair_costs;
        if (eval{$building->can_repair($costs)}) {
            $building->repair($costs);            
        }
        else {
            $self->pass_extra_message('Unfortunately, by the time the proposition passed, there weren\'t enough resources in storage to repair the module, effectively nullifying the vote.');
        }
    }
    else {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the module had been demolished, effectively nullifying the vote.');
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
