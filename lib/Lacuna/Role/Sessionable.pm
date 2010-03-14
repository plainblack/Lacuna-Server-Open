package Lacuna::Role::Sessionable;

use Moose::Role;
use DateTime;
use Lacuna::Util qw(format_date);

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
        if (!defined $session) {
            confess [1006, 'Session not found.', $session_id];
        }
        elsif ($session->has_expired) {
		    my $now = format_date(DateTime->now);
		    my $expires = format_date($session->expires);
            confess [1006, 'Session expired.', {session_id=>$session_id, now=>$now, expired=>$expires}];
        }
        else {
	    $session->extend;
            return $session;
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
