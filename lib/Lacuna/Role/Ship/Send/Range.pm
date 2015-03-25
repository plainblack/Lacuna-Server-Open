package Lacuna::Role::Ship::Send::Range;

use strict;
use Moose::Role;

after can_send_to_target => sub {
    my ($self, $target) = @_;

    my $distance = $self->body->calculate_distance_to_target($target);
    my $range = $self->speed;
# Note that $distance is actually *100 further, so we'll divide before output if needed.
    if ($distance > $range) {
      $distance = $distance/100;
      $range    = $range/100;
      confess [1009, sprintf("You only have a range of %0.2f with this ship. This body is %0.2f units away.",$range,$distance)];
    }
};

1;
