package Lacuna::RPC::Building::SubspaceSupplyDepot;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/subspacesupplydepot';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::SubspaceSupplyDepot';
}

sub transmit_food {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $building->transmit_food;
    return {
        status      => $self->format_status($empire, $building->body),
        building                    => {
            work        => {
                seconds_remaining   => $building->work_seconds_remaining,
                start               => $building->work_started_formatted,
                end                 => $building->work_ends_formatted,
            },
        },
    };
}

sub transmit_energy {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $building->transmit_energy;
    return {
        status      => $self->format_status($empire, $building->body),
        building                    => {
            work        => {
                seconds_remaining   => $building->work_seconds_remaining,
                start               => $building->work_started_formatted,
                end                 => $building->work_ends_formatted,
            },
        },
    };
}

sub transmit_ore {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $building->transmit_ore;
    return {
        status      => $self->format_status($empire, $building->body),
        building                    => {
            work        => {
                seconds_remaining   => $building->work_seconds_remaining,
                start               => $building->work_started_formatted,
                end                 => $building->work_ends_formatted,
            },
        },
    };
}

sub transmit_water {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $building->transmit_water;
    return {
        status      => $self->format_status($empire, $building->body),
        building                    => {
            work        => {
                seconds_remaining   => $building->work_seconds_remaining,
                start               => $building->work_started_formatted,
                end                 => $building->work_ends_formatted,
            },
        },
    };
}

sub complete_build_queue {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $building->complete_build_queue;
    return {
        status      => $self->format_status($empire, $building->body),
        building                    => {
            work        => {
                seconds_remaining   => $building->work_seconds_remaining,
                start               => $building->work_started_formatted,
                end                 => $building->work_ends_formatted,
            },
        },
    };
}

__PACKAGE__->register_rpc_method_names(qw(transmit_energy transmit_ore transmit_food complete_build_queue transmit_water));

no Moose;
__PACKAGE__->meta->make_immutable;

