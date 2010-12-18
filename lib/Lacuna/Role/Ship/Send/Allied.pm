package Lacuna::Role::Ship::Send::Allied;

use strict;
use Moose::Role;

after can_send_to_target => sub {
    my ($self, $target) = @_;
    confess [1009, 'Cannot send yet.'];
};

1;
