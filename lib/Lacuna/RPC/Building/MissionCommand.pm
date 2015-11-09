package Lacuna::RPC::Building::MissionCommand;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/missioncommand';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::MissionCommand';
}

sub get_missions {
    my ($self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my @missions;
    my $missions = $building->missions;
    my $count;
    my @listed;
    while (my $mission = $missions->next) {
        my $params = $mission->params;
        next if $mission->mission_file_name ~~ \@listed;
        next if $params->get('max_university_level') < $empire->university_level;
        next if Lacuna->cache->get($mission->mission_file_name, $empire->id);
        push @listed, $mission->mission_file_name;
        my $objectives = $mission->format_objectives;
        next unless defined($objectives);
        my $rewards = $mission->format_rewards;
        next unless defined($rewards);
        push @missions, {
            id                      => $mission->id,
            name                    => $params->get('name'),
            description             => $params->get('description'),
            objectives              => $objectives,
            rewards                 => $rewards,
            max_university_level    => $params->get('max_university_level'),
            date_posted             => $mission->date_posted_formatted,
        };
        $count++;
        last if ($count >= $building->effective_level);
    }
    return {
        status      => $self->format_status($empire, $building->body),
        missions    => \@missions,
    };
}

sub complete_mission {
    my ($self, $session_id, $building_id, $mission_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    confess [1002, 'Please specify a mission id.'] unless $mission_id;
    my $mission = $building->missions->find($mission_id);
    confess [1002, 'No such mission.'] unless $mission;
    # this check is repeated later to avoid race conditions, but done early
    # to give more meaningful errors to those not trying to game the system.
    confess [1002, 'Already completed that mission in another zone.']
        if Lacuna->cache->get($mission->mission_file_name, $empire->id);
    my $body = $building->body;
    $mission->check_objectives($body);
    $mission->complete($body);
    return {
        status      => $self->format_status($empire, $body),
    }
}

sub skip_mission {
    my ($self, $session_id, $building_id, $mission_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    confess [1002, 'Please specify a mission id.'] unless $mission_id;
    my $mission = $building->missions->find($mission_id);
    confess [1002, 'No such mission.'] unless $mission;
    my $body = $building->body;
    $mission->skip($body);
    return {
        status      => $self->format_status($empire, $body),
    }
}

__PACKAGE__->register_rpc_method_names(qw(get_missions skip_mission complete_mission));

no Moose;
__PACKAGE__->meta->make_immutable;

