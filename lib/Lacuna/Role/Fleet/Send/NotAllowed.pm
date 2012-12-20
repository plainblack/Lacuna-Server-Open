package Lacuna::Role::Fleet::Send::NotAllowed;

use strict;
use Moose::Role;

after can_send_to_target => sub {
    my ($self, $target) = @_;
    confess [1009, 'Cannot be sent'];
};

1;
