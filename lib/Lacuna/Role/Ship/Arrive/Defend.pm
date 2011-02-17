package Lacuna::Role::Ship::Arrive::Defend;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # no defense at stars
    return unless $self->foreign_body_id;

	# only defend on arrival to the foreign body
	return if $self->direction eq 'in';

	# who do we protect?
    my $body_defending = $self->foreign_body;

	$self->defend->update;

	confess [-1];
};

1;
