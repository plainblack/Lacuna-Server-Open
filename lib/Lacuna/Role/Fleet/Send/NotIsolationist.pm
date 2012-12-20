package Lacuna::Role::Fleet::Send::NotIsolationist;

use strict;
use Moose::Role;

after can_send_to_target => sub {
    my ($self, $target) = @_;
    if ( $target->empire && $target->empire->is_isolationist ) {
        confess [1013, sprintf('%s is an isolationist empire, and must be left alone.',$target->empire->name)];
    }
};

1;
