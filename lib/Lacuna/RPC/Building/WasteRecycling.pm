package Lacuna::RPC::Building::WasteRecycling;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/wasterecycling';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Waste::Recycling';
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id, skip_offline => 1 });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $out = $orig->($self, $session, $building);
    if ($building->is_working) {
        $out->{recycle} = {
            seconds_remaining   => $building->work_seconds_remaining,
            water               => $building->work->{water_from_recycling},
            ore                 => $building->work->{ore_from_recycling},
            energy              => $building->work->{energy_from_recycling},
            can                 => 0,
        };
    }
    else {
        $out->{recycle}{can}     = (eval { $building->can_recycle(1) }) ? 1 : 0;
    }
    $out->{recycle}{seconds_per_resource} = $building->seconds_per_resource;
    $out->{recycle}{max_recycle} = $building->max_recycle;
    return $out;
};

sub recycle {
    my ($self, $session_id, $building_id, $water, $ore, $energy, $use_essentia) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    $building->recycle($water, $ore, $energy, $use_essentia);
    return $self->view($session, $building);
}

sub subsidize_recycling {
    my ($self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;

    unless ($building->is_working) {
        confess [1010, "The Recycling Center isn't recycling anything."];
    }
 
    unless ($empire->essentia >= 2) {
        confess [1011, "Not enough essentia."];
    }

    $building->finish_work->update;
    $empire->spend_essentia({
        amount      => 2,
        reason      => 'recycling subsidy after the fact',
    });
    $empire->update;

    return $self->view($session, $building);
}

__PACKAGE__->register_rpc_method_names(qw(recycle subsidize_recycling));

no Moose;
__PACKAGE__->meta->make_immutable;

