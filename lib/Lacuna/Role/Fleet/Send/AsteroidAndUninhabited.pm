package Lacuna::Role::Fleet::Send::AsteroidAndUninhabited;

use strict;
use Moose::Role;

after can_send_to_target => sub {
    my ($self, $target) = @_;
    confess [1009, 'Can only be sent to asteroids and uninhabited planets.'] unless
      ( $target->isa('Lacuna::DB::Result::Map::Body::Asteroid') ||
       ($target->isa('Lacuna::DB::Result::Map::Body::Planet') and !(defined($target->empire_id)) ));
};

1;
