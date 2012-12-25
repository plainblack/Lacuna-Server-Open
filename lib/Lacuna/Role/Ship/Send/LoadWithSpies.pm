package Lacuna::Role::Ship::Send::LoadWithSpies;

use strict;
use Moose::Role;

after send => sub {
    my $self = shift;
    return if ( $self->direction eq 'in' && $self->type ne 'spy_shuttle' ); # load outbound ships and inbound spy shuttles
    return if ( $self->payload->{mercenary} ); # Mercenary already loaded
    return if ( $self->payload->{spies} ); # Spies already loaded
    my $arrives = DateTime->now->add(seconds=>$self->calculate_travel_time($self->foreign_body));
    my @spies;
    my $to_body = $self->direction eq 'out' ? $self->foreign_body : $self->body;
    foreach my $spy (@{$self->get_available_spies_to_send}) {
        $spy->send($to_body->id, $arrives)->update;
        push @spies, $spy->id;
    }
    $self->payload({ spies => \@spies });
    $self->update;
};

after can_send_to_target => sub {
    my ($self, $target) = @_;
    return if ( $self->direction eq 'in' ); # Only applies to outbound ships
    return if ( $self->type eq 'spy_shuttle' ); # Except for spy shuttles
    confess [ 1002, 'You have no idle spies to send.'] unless (scalar(@{$self->get_available_spies_to_send}));
};

sub get_available_spies_to_send {
    my $self = shift;
    my $body = $self->body;
    my $on_body = $self->direction eq 'in' ? $self->foreign_body : $self->body;
    my @spies;
    if ($on_body) {
        my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search(
            { task => { in => ['Idle','Counter Espionage'] }, on_body_id=>$on_body->id, empire_id=>$body->empire->id },
        );
        while (my $spy = $spies->next) {
            if ($spy->is_available) {
                push @spies, $spy;
                last if (scalar(@spies) >= $self->max_occupants);
            }
        }
    }
    return \@spies;
}

1;
