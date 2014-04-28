package Lacuna::DB::Result::Proposition::UpgradeModule;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Proposition';

before pass => sub {
    my ($self) = @_;
    my $building = $self->station->find_building($self->scratch->{building_id});
    if (defined $building) {
        if ($building->is_upgrading && $building->level < $self->scratch->{to_level}) {
            $building->finish_upgrade;
        }
    }
    else {
        $self->pass_extra_message('Unfortunately by the time the proposition passed, the module had been demolished, effectively nullifying the vote.');
    }
};

before fail => sub {
    my ($self) = @_;
    my $station = $self->station;
    my $building = $station->find_building($self->scratch->{building_id});
    if (defined $building) {
        $station->add_plan($building->class, $building->level + 1);
        if ($building->level == 0 ) {
            $building->demolish;
        }
        else {
            $building->is_upgrading(0);
            $building->update;
        }
    }
    else {
        $self->pass_extra_message('Unfortunately by the time the proposition passed, the module had been demolished, effectively nullifying the vote.');
    }
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
