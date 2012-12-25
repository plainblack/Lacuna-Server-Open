package Lacuna::Role::Ship::Arrive::Scuttle;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;
    $self->delete;
    confess [-1];
};


1;
