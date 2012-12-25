package Lacuna::Role::Fleet::Send::MemberOfAlliance;

use strict;
use Moose::Role;

after can_send_to_target => sub {
    my ($self, $target ) = @_;
    confess [1013, 'You must be part of an alliance.'] unless ($self->body->empire->alliance_id);
};

1;
