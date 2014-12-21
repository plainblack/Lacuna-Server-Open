package Lacuna::Role::Ship::Arrive::GroupHome;

use strict;
use Moose::Role;
use Lacuna::Util qw(randint);
use DateTime;

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # we're coming home
    my $payload = $self->payload;
    if ($self->direction eq 'in') {
        for my $part (@{$payload->{fleet}}) {
            if ($part->{type} eq "sweeper") {
                for my $num (1..$part->{quantity}) {
                    my $ship = Lacuna->db->resultset('Ships')->new({type => "sweeper"});
                    $ship->name($part->{name});
                    $ship->body_id($self->body_id);
                    $ship->speed($part->{speed});
                    $ship->combat($part->{combat});
                    $ship->stealth($part->{stealth});
                    $ship->hold_size(0);
                    $ship->date_available(DateTime->now);
                    $ship->date_started(DateTime->now);
                    $ship->insert;
                }
            }
        }
        $self->delete;
        confess[-1];
    }

# If not, strip all but sweepers and we'll turn around
    my @new_fleet;
    my $new_combat = 0;
    my $new_quantity = 0;
    my $new_stealth = 50_000;
    my $new_speed = 50_000;
    for my $part (@{$payload->{fleet}}) {
        if ($part->{type} eq "sweeper") {
            $new_quantity += $part->{quantity};
            $new_combat += $part->{combat};
            $new_stealth = $part->{stealth} if ($part->{stealth} < $new_stealth);
            $new_speed = $part->{speed} if ($part->{speed} < $new_speed);
            push @new_fleet, $part;
        }
    }
    if ($new_quantity > 0 and $new_combat > 0) {
        $payload = {
            fleet => \@new_fleet,
            quantity => $new_quantity,
            damage_taken => 0,
        };
        $self->combat($new_combat);
        $self->stealth($new_stealth);
        $self->speed($new_speed);
        $self->fleet_speed($new_speed);
    }
    else {
        $self->delete;
        confess[-1];
    }
    return;
};

1;
