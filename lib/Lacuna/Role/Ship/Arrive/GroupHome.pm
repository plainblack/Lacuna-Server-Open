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
        for my $key ( sort keys %{$payload->{fleet}}) {
            if ($payload->{fleet}->{$key}->{type} eq "sweeper") {
                for my $num (1..$payload->{fleet}->{$key}->{quantity}) {
                    my $ship = Lacuna->db->resultset('Ships')->new({
                        type           => "sweeper",
                        name           => $payload->{fleet}->{$key}->{name},
                        shipyard_id    => 42,
                        speed          => $payload->{fleet}->{$key}->{speed},
                        combat         => $payload->{fleet}->{$key}->{combat},
                        stealth        => $payload->{fleet}->{$key}->{stealth},
                        hold_size      => 0,
                        date_available => DateTime->now,
                        date_started   => DateTime->now,
                        body_id        => $self->body_id,
                        task           => "Docked",
                    })->insert;
                }
            }
        }
        $self->delete;
        confess[-1];
    }

# If not, strip all but sweepers and we'll turn around
    my $new_payload;
    my $new_combat = 0;
    my $new_quantity = 0;
    my $new_stealth = 50_000;
    my $new_speed = 50_000;
    for my $key (sort keys %{$payload->{fleet}}) {
        if ($payload->{fleet}->{"$key"}->{type} eq "sweeper") {
            $new_quantity += $payload->{fleet}->{"$key"}->{quantity};
            $new_combat += $payload->{fleet}->{"$key"}->{combat} * $payload->{fleet}->{"$key"}->{quantity};
            $new_stealth = $payload->{fleet}->{"$key"}->{stealth} if ($payload->{fleet}->{"$key"}->{stealth} < $new_stealth);
            $new_speed = $payload->{fleet}->{"$key"}->{speed} if ($payload->{fleet}->{"$key"}->{speed} < $new_speed);
            $new_payload->{fleet}->{"$key"} = $payload->{fleet}->{"$key"};
        }
    }
    if ($new_quantity > 0 and $new_combat > 0) {
        $payload = $new_payload;
        $self->payload($payload);
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
