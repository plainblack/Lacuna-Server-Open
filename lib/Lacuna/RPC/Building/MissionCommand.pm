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
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my @missions;
    my $missions = $building->missions;
    while (my $mission = $missions->next) {
        next if $mission->params->max_university_level < $empire->university_level;
        next if Lacuna->cache->get($mission->mission_file_name, $empire->id);
        push @missions, {
            id                      => $mission->id,
            name                    => $mission->name,
            description             => $mission->description,
            objectives              => $mission->format_objectives,
            rewards                 => $mission->format_rewards,
            max_university_level    => $mission->max_university_level,
            date_posted             => $mission->date_posted_formatted,
        };
    }
    return {
        status      => $self->format_status($empire, $building->body),
        missions    => \@missions,
    };
}

sub complete_mission {
    my ($self, $session_id, $building_id, $mission_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    confess [1002, 'Please specify a mission id.'] unless $mission_id;
    my $mission = $building->missions->find($mission_id);
    my $body = $building->body;
    $mission->check_objectives($body);
    $mission->spend_objectives($body);
    $mission->add_rewards($body);
    Lacuna->cache->set($mission->mission_file_name, $empire->id, 1, 60 * 60 * 24 * 30);
    return {
        status      => $self->format_status($empire, $body),
    }
}

__PACKAGE__->register_rpc_method_names(qw(get_missions complete_mission));

no Moose;
__PACKAGE__->meta->make_immutable;

