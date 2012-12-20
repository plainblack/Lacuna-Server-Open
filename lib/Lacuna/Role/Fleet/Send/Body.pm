package Lacuna::Role::Fleet::Send::Body;

use strict;
use Moose::Role;

after can_send_to_target => sub {
    my ($self, $target) = @_;
    confess [1009, 'Can only be sent to bodies.'] unless ($target->isa('Lacuna::DB::Result::Map::Body'));
};

1;
