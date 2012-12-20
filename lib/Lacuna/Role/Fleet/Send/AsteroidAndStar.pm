package Lacuna::Role::Fleet::Send::AsteroidAndStar;

use strict;
use Moose::Role;

after can_send_to_target => sub {
    my ($self, $target) = @_;
    confess [1009, 'Can only be sent to asteroids and stars.'] unless ($target->isa('Lacuna::DB::Result::Map::Body::Asteroid') || $target->isa('Lacuna::DB::Result::Map::Star'));
};

1;
