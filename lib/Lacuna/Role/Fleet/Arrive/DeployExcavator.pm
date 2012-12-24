package Lacuna::Role::Fleet::Arrive::DeployExcavator;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # we're coming home
    return if ($self->direction eq 'in');
    
    # do we have archaeology of level 11 or greater, if not, turn around
    my $body = $self->body;
    my $archaeology = $body->archaeology;
    return unless ((defined $archaeology) && ($archaeology->level >= 11));

    # can we deploy a excavator
    my $empire = $body->empire;
    my $foreign_body = $self->foreign_body;
    my $can = eval{$archaeology->can_add_excavator($foreign_body, 1)};
    my $reason = $@;

    if ($can && !$reason) {
        # yes, we can
        $archaeology->add_excavator($foreign_body)->update;
        $empire->send_predefined_message(
            tags        => ['Excavator','Alert'],
            filename    => 'excavator_deployed.txt',
            params      => [$body->id, $body->name, $foreign_body->x, $foreign_body->y, $foreign_body->name, $self->name],
        ) unless ( $empire->skip_excavator_replace_msg );
        $self->delete;
        confess [-1];
    }
    else {
        # no we can't
        my $message = (ref $reason eq 'ARRAY') ? $reason->[1] : 'We have encountered a glitch.';
        $empire->send_predefined_message(
            tags        => ['Excavator','Alert'],
            filename    => 'cannot_deploy_excavator.txt',
            params      => [$message, $foreign_body->x, $foreign_body->y, $foreign_body->name, $body->id, $body->name, $self->name],
        );
    }
};

after can_send_to_target => sub {
    my ($self, $target) = @_;

    confess [1009, 'Can only be sent to asteroids and habitable planets.'] if ($target->isa('Lacuna::DB::Result::Map::Body::Planet::GasGiant'));
    my $archaeology = $self->body->archaeology;
    confess [1013, 'Cannot control excavators without an Archaeology.'] unless (defined $archaeology);
    confess [1013, 'Your Archaeology Ministry must be level 11 or higher in order to send excavators.'] unless ($archaeology->level >= 11);
    $archaeology->can_add_excavator($target);
    if ($target->star->station_id) {
        if ($target->star->station->laws->search({type => 'MembersOnlyExcavation'})->count) {
            unless ($target->star->station->alliance_id == $self->body->empire->alliance_id) {
                confess [1010, 'Only '.$target->star->station->alliance->name.' members can excavate bodies in the jurisdiction of the space station.'];
            }
        }
    }
};

1;
