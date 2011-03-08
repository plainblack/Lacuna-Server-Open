package Lacuna::Role::Captcha::Spies;

use Moose::Role;

before 'assign_spy' => sub {
    my ($self, $session_id, $building_id, $spy_id, $assignment) = @_;
    my $empire = $self->get_empire_by_session($session_id);
	unless ($empire->current_session->check_captcha()) {
		confess [1016,'Needs to solve a captcha.'];
	}
};


1;
