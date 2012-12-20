package Lacuna::Role::Fleet::Send::Asteroid;

use strict;
use Moose::Role;

after can_send_to_target => sub {
    my ($self, $target) = @_;
    confess [1009, 'Can only be sent to asteroids.'] unless ($target->isa('Lacuna::DB::Result::Map::Body::Asteroid'));
};

1;
