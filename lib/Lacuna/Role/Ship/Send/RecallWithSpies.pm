package Lacuna::Role::Ship::Send::RecallWithSpies;

use strict;
use Moose::Role;

after send => sub {
    my $self = shift;
    return if ( $self->direction eq 'out' ); # only load up on recall
    return if ( $self->payload->{spies}[0] ); # Spies loaded
    my $arrives = DateTime->now->add(seconds=>$self->calculate_travel_time($self->foreign_body));
    my @spies;
    my $body = $self->body;
    foreach my $spy (@{$self->get_available_spies_to_send}) {
        $spy->send($body->id, $arrives)->update;
        push @spies, $spy->id;
    }
    $self->payload({ spies => \@spies });
    $self->update;
};

sub get_available_spies_to_send {
    my $self = shift;
    my $body = $self->body;
    my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search(
        {task => ['in','Idle','Training'], on_body_id=>$self->foreign_body_id, empire_id=>$body->empire->id},
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
