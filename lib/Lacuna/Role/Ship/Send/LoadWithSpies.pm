package Lacuna::Role::Ship::Send::LoadWithSpies;

use strict;
use Moose::Role;

with 'Lacuna::Role::Captcha::Ships';

after send => sub {
    my $self = shift;
    return if $self->payload->{spies}[0];
    my $arrives = DateTime->now->add(seconds=>$self->calculate_travel_time($self->foreign_body));
    my @spies;
    foreach my $spy (@{$self->get_available_spies_to_send}) {
        $spy->send($self->foreign_body_id, $arrives)->update;
        push @spies, $spy->id;
    }
    $self->payload({ spies => \@spies });
    $self->update;
};

after can_send_to_target => sub {
    my ($self, $target) = @_;
    confess [ 1002, 'You have no idle spies to send.'] unless (scalar(@{$self->get_available_spies_to_send}));
};

sub get_available_spies_to_send {
    my $self = shift;
    my $body = $self->body;
    my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search(
        {task => ['in','Idle','Training'], on_body_id=>$body->id, empire_id=>$body->empire->id},
    );
    my @spies;
    while (my $spy = $spies->next) {
        if ($spy->is_available) {
            push @spies, $spy;
            last if (scalar(@spies) >= $self->max_occupants);
        }
    }
    return \@spies;
}

1;
