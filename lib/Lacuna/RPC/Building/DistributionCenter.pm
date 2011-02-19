package Lacuna::RPC::Building::DistributionCenter;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/distributioncenter';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::DistributionCenter';
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id, skip_offline => 1);
    my $out = $orig->($self, $empire, $building);
    if ($building->is_working) {
        $out->{reserve} = {
            resources           => $building->work->{reserved},
            seconds_remaining   => $building->work_seconds_remaining,
            can                 => 0,
        };
    }
    else {
        $out->{reserve}{can}   = (eval { $building->can_reserve }) ? 1 : 0;
    }
    $out->{reserve}{max_reserve_duration} = $building->reserve_duration;
    $out->{reserve}{max_reserve_size} = $building->max_reserve_size;
    return $out;
};

sub reserve {
    my ($self, $session_id, $building_id, $resources) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $building->reserve($resources);
    return $self->view($empire, $building);
}

sub release_reserve {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $building->release_reserve;
    return $self->view($empire, $building);
}

__PACKAGE__->register_rpc_method_names(qw(reserve release_reserve));


no Moose;
__PACKAGE__->meta->make_immutable;

