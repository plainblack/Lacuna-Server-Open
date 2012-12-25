package Lacuna::Role::Ship::Send::Inhabited;

use strict;
use Moose::Role;

after can_send_to_target => sub {
    my ($self, $target) = @_;
    confess [1013, 'Can only be sent to inhabited planets.'] unless ($target->empire_id);
};

1;
