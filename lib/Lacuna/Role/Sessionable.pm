package Lacuna::Role::Sessionable;

use Moose::Role;

requires 'simpledb';

sub is_session_valid {
    my ($self, $session_id) = @_;
    my $session = eval{$self->get_session($session_id)};
    return (defined $session);
}

sub get_session {
    my ($self, $session_id) = @_;
    if (ref $session_id eq 'Lacuna::DB::Session') {
        return $session_id;
    }
    else {
        my $session = $self->simpledb->domain('session')->find($session_id);
        if (defined $session && !$session->has_expired) {
            return $session;
        }
        else {
            confess [1006, 'Authorization denied.', $session_id];
        }
    }
}

sub get_empire_by_session {
    my ($self, $session_id) = @_;
    if (ref $session_id eq 'Lacuna::DB::Empire') {
        return $session_id;
    }
    else {
        my $empire = $self->get_session($session_id)->empire;
        if (defined $empire) {
            return $empire;
        }
        else {
            confess [1002, 'Empire does not exist.'];
        }
    }
}


1;
