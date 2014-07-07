package Lacuna::Role::Ship::Arrive::DeployMiningPlatform;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # we're coming home
    return if ($self->direction eq 'in');
    
    # do we have a mining ministry, if not, turn around
    my $body = $self->body;
    my $ministry = $body->mining_ministry;
    return unless (defined $ministry);

    # can we deploy a platform
    my $empire = $body->empire;
    my $foreign_body = $self->foreign_body;
    my $can = eval{$ministry->can_add_platform($foreign_body, 1)};
	my $reason = $@;

    # yes, we can
    if ($can && !$reason) {
        $ministry->add_platform($foreign_body)->update;
        $empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'mining_platform_deployed.txt',
            params      => [$body->id, $body->name, $foreign_body->x, $foreign_body->y, $foreign_body->name, $self->name],
        );
        $self->delete;
        my $type = ref $foreign_body;
        $type =~ s/^.*::(\w\d+)$/$1/;
        $empire->add_medal($type);
        confess [-1];
    }

    # no we can't
    else {
        my $message = (ref $reason eq 'ARRAY') ? $reason->[1] : 'We have encountered a glitch.';
        $empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'cannot_deploy_mining_platform.txt',
            params      => [$message, $foreign_body->x, $foreign_body->y, $foreign_body->name, $body->id, $body->name, $self->name],
        );
    }
};

after can_send_to_target => sub {
    my ($self, $target) = @_;
    my $ministry = $self->body->mining_ministry;
    confess [1013, 'Cannot control platforms without a Mining Ministry.'] unless (defined $ministry);
    $ministry->can_add_platform($target);
    if ($target->star->is_seized) {
        if ($target->star->alliance->laws->search({
            type    => 'MembersOnlyMiningRights',
            zone    => $target->star->zone,
        })->count) {
            unless ($target->star->alliance_id == $self->body->empire->alliance_id) {
                confess [1010, 'Only '.$target->star->alliance->name.' members can mine asteroids under their influence in zone '.$target->star->zone.'.'];
            }
        }
    }
};

1;
