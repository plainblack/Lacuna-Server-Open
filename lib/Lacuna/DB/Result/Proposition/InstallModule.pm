package Lacuna::DB::Result::Proposition::InstallModule;

use Moose;
use utf8;
use Data::Dumper;

no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Proposition';

before pass => sub {
    my ($self) = @_;
    my $station = $self->station;
    my $building = $self->station->find_building($self->scratch->{building_id});
    if (defined $building) {
        if ($building->is_upgrading && $building->level < $self->scratch->{to_level}) {
            $building->finish_upgrade;
        }
    }
    else {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the module had been demolished, effectively nullifying the vote.');
    }
};

before fail => sub {
    my ($self) = @_;
    my $station = $self->station;
    my $building = $station->find_building($self->scratch->{building_id});
    if (defined $building) {
        $station->add_plan($building->class, 1, $building->level);
        $building->demolish;
    }
    else {
        $self->pass_extra_message('Unfortunately by the time the proposition passed, the module had been demolished, effectively nullifying the vote.');
    }
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
