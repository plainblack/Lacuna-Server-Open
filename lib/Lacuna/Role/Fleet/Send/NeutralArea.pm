package Lacuna::Role::Fleet::Send::NeutralArea;

use strict;
use Moose::Role;

after can_send_to_target => sub {
    my ($self, $target) = @_;

    # For scows to be sent to stars.  Still allows Detonators to stars, but not as bad of an issue for now.
    return 1 if ($target->isa('Lacuna::DB::Result::Map::Star'));

    if (defined $target->empire_id) {
        return 1 if ($target->empire_id == $self->body->empire_id);  # We don't care if people hit themselves.
    }

    confess [1009, 'Can not be sent from the Neutral Area.'] if $self->body->in_neutral_area;
    confess [1009, 'Can not be sent to the Neutral Area.']   if $target->in_neutral_area;

};

1;
