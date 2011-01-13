package Lacuna::Role::Ship::Arrive::CargoExchange;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;
    if (!$self->foreign_body->empire_id) {
        # do nothing, because it is uninhabited
    }
    elsif ($self->direction eq 'out') {
        $self->unload($self->foreign_body);
    }
    else {
        $self->unload($self->body);
    }
};

1;
