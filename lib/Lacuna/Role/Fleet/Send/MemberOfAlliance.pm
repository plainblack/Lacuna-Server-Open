package Lacuna::Role::Fleet::Send::MaybeHostile;

use strict;
use Moose::Role;

after can_send_to_target => sub {
    my ($self, $target ) = @_;
    if ($target->isa('Lacuna::DB::Result::Map::Body')) {
        if ($target->empire_id && $target->empire_id != $self->body->empire_id) {
            $self->hostile_action(1);
        }
    }
};

1;
