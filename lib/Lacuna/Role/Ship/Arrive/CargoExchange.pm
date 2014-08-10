package Lacuna::Role::Ship::Arrive::CargoExchange;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;
    
    if ($self->direction eq 'out' and $self->foreign_body->empire_id) {
        $self->unload($self->foreign_body);
    }
    elsif ($self->direction eq 'in') {
        $self->unload($self->body);
    }
};

1;
