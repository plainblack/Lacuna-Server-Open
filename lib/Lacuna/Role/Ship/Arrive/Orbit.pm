package Lacuna::Role::Ship::Arrive::Orbit;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # cannot orbit stars
    return unless $self->foreign_body_id;

	# only orbit on arrival to the foreign body
	return if $self->direction eq 'in';

    # we don't orbit if there are spies
    return if (
        (exists $self->payload->{spies} && scalar(@{$self->payload->{spies}})) ||
        (exists $self->payload->{fetch_spies} && scalar(@{$self->payload->{fetch_spies}}))
    );

	$self->orbit->update;

	confess [-1];
};

1;
