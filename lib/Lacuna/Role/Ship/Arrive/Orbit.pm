package Lacuna::Role::Ship::Arrive::Orbit;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # cannot orbit stars
    return unless $self->foreign_body_id;

    # only orbit on arrival to the foreign body
    return if $self->direction eq 'in';

    return if ( $self->payload->{fetch_spies} ); # Don't orbit if we're fetching
    $self->orbit->update;

    confess [-1];
};

1;
