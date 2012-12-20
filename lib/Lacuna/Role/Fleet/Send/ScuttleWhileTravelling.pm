package Lacuna::Role::Fleet::Send::ScuttleWhileTravelling;

use strict;
use Moose::Role;

around 'can_scuttle' => sub {
    my $orig = shift;
    my $self = shift;

    if ($self->task eq 'Travelling') {
        return 1;
    }
    $self->$orig(@_);
};

1;
