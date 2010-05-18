package Lacuna::RPC::Building::WasteRecycling;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/wasterecycling';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Waste::Recycling';
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    my $out = $orig->($self, $empire, $building);
    if ($building->is_working) {
        $out->{recycle} = {
            seconds_remaining   => $building->work_seconds_remaining,
            water               => $building->work->{water_from_recycling},
            ore                 => $building->work->{ore_from_recycling},
            energy              => $building->work->{energy_from_recycling},
        };
    }
    else {
        $out->{recycle}{can} = (eval { $building->can_recycle }) ? 1 : 0;
        $out->{recycle}{seconds_per_resource} = 10 * $building->time_cost_reduction_bonus($building->level * 2);
    }
    return $out;
};

sub recycle {
    my ($self, $session_id, $building_id, $water, $ore, $energy, $use_essentia) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    $building->recycle($water, $ore, $energy, $use_essentia);
    return {
        seconds_remaining   => $building->work_seconds_remaining,
        status              => $empire->get_status,
    };    
}

sub subsidize_recycling {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);

    unless ($empire->essentia >= 2) {
        confess [1011, "Not enough essentia."];    
    }

    $building->finish_work->update;
    $empire->spend_essentia(2);    
    $empire->trigger_full_update(skip_put => 1);
    $empire->update;

    return {
        status              => $empire->get_status,
    };    
}

__PACKAGE__->register_rpc_method_names(qw(recycle subsidize_recycling));

no Moose;
__PACKAGE__->meta->make_immutable;

