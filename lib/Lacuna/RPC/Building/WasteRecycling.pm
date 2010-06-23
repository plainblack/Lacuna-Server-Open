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
    my $building = $self->get_building($empire, $building_id);
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
        $out->{recycle} = {
            can                     => (eval { $building->can_recycle }) ? 1 : 0,
            seconds_per_resource    => $building->seconds_per_resource,
            max_recycle             => $building->max_recycle,
        };
    }
    return $out;
};

sub recycle {
    my ($self, $session_id, $building_id, $water, $ore, $energy, $use_essentia) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $building->recycle($water, $ore, $energy, $use_essentia);
    return {
        seconds_remaining   => $building->work_seconds_remaining,
        status              => $self->format_status($empire, $building->body),
    };    
}

sub subsidize_recycling {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);

    unless ($building->is_working) {
        confess [1010, "The Recycling Center isn't recycling anything."];
    }
 
    unless ($empire->essentia >= 2) {
        confess [1011, "Not enough essentia."];    
    }

    $building->finish_work->update;
    $empire->spend_essentia(2, 'recycling subsidy after the fact');    
    $empire->update;

    return {
        status              => $self->format_status($empire, $building->body),
    };    
}

__PACKAGE__->register_rpc_method_names(qw(recycle subsidize_recycling));

no Moose;
__PACKAGE__->meta->make_immutable;

