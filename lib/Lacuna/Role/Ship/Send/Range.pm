package Lacuna::Role::Ship::Send::Range;

use strict;
use Moose::Role;

after can_send_to_target => sub {
    my ($self, $target) = @_;

    my $distance = $self->body->calculate_distance_to_target($target);
    my $range = int($self->speed/100+0.5);
    if ($distance > $range) {
      confess [1009, 'You only have a range of '.$range.' with this ship.'];
    }
};

1;
