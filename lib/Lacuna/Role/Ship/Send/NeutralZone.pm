package Lacuna::Role::Ship::Send::NeutralZone;

use strict;
use Moose::Role;

after can_send_to_target => sub {
    my ($self, $target) = @_;
    confess [1009, 'Can not be sent from the Neutral Zone.'] if $self->in_neutral_zone;
    confess [1009, 'Can not be sent to the Neutral Zone.']   if $target->in_neutral_zone;

1;
