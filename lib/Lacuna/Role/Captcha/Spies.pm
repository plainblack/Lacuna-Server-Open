package Lacuna::Role::Captcha::Spies;

use Moose::Role;

before 'assign' => sub {
	my ($self, $assignment) = @_;
	my $empire = $self->empire();
	my $session = $empire->current_session; # this is undefined?!??
	unless ($session->check_captcha()) {
		confess [1016,'Needs to solve a captcha.'];
	}
};


=pod
before 'assign_spy' => sub {
    my ($self, $session_id, $building_id, $spy_id, $assignment) = @_;
    my $empire = $self->get_empire_by_session($session_id);
#	my $session = $empire->current_session;
	unless ($empire->current_session->check_captcha()) {
		confess [1016,'Needs to solve a captcha.'];
	}
}
=cut


1;
