package Lacuna::Role::Fleet::Arrive::Defend;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # no defense at stars
    return unless $self->foreign_body_id;

    # only defend on arrival to the foreign body
    return if $self->direction eq 'in';

    $self->defend->update;

    confess [-1];
};

1;
