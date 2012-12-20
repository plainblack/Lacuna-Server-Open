package Lacuna::Role::Fleet::Send::RecallWhileTravelling;

use strict;
use Moose::Role;

around 'can_recall' => sub {
    my $orig = shift;
    my $self = shift;

    if ($self->task eq 'Travelling' and $self->direction eq 'out') {
        return 1;
    }
    $self->$orig(@_);
};

1;
