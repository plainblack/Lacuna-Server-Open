package Lacuna::Role::Ship::Send::UsePush;

use strict;
use Moose::Role;

after can_send_to_target => sub {
    my ($self, $target) = @_;
    confess [1009, 'Use the "push" feature in the Trade Ministry to send this ship to another planet.'];
};

1;
