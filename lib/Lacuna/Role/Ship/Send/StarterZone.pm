package Lacuna::Role::Ship::Send::StarterZone;

use strict;
use Moose::Role;

after can_send_to_target => sub {
    my ($self, $target) = @_;

    my $sz_param = Lacuna->config->get('starter_zone');
    if ($sz_param) {
        return 1 unless $target->in_starter_zone;

        confess [1009, 'Can not establish Space Stations in starter zones'] if ($self->type eq 'space_station');

        if ($sz_param->{max_colonies}) {
            my $sz_colonies = 0;
            my $planets = $self->body->empire->planets;
            while (my $planet = $planets->next) {
                $sz_colonies++ if $planet->in_starter_zone;
            }
            confess [1009, 'You already have the maximum allowed colonies in starter zones.'] if ($sz_colonies >= $sz_param->{max_colonies});
        }
    }
    return 1;
};

1;
