package Lacuna::Role::Fleet::Send::Range;

use strict;
use Moose::Role;

after can_send_to_target => sub {
    my ($self, $target) = @_;

    my $distance = $self->body->calculate_distance_to_target($target);
    my $range = $self->speed;
    # Note that $distance is actually *100 further, so we'll divide before output if needed.
    if ($distance > $range) {
        $distance = int($distance/100+0.5);
        $range    = int($range/100+0.5);
        confess [1009, 'You only have a range of '.$range.' with this fleet. This body is '.$distance.' away.'];
    }
};

1;
