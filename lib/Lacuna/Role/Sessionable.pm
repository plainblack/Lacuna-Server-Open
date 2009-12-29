package Lacuna::Role::Sessionable;

use Moose::Role;

requires 'simpledb';

sub is_session_valid {
    my ($self, $session_id) = @_;
    my $session = $self->simpledb->domain('session')->find($session_id);
    return (defined $session);
}

sub get_empire_by_session {
    my ($self, $session_id) = @_;
    my $session = $self->simpledb->domain('session')->find($session_id);
    if (defined $session) {
        return $session->empire;
    }
    return undef;
}


1;
