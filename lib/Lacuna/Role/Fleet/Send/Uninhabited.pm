package Lacuna::Role::Fleet::Send::Uninhabited;

use strict;
use Moose::Role;

after can_send_to_target => sub {
    my ($self, $target) = @_;
    confess [1013, 'Can only be sent to uninhabited planets.'] if ($target->empire_id);
};

1;
