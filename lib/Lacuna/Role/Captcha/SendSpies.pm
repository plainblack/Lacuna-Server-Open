package Lacuna::Role::Captcha::SendSpies;

use Moose::Role;

before 'prepare_send_spies' => sub {
    my ($self, $session_id, $on_body_id, $to_body_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
	unless ($empire->current_session->check_captcha()) {
		confess [1016,'Needs to solve a captcha.'];
	}
};

before 'send_spies' => sub {
    my ($self, $session_id, $on_body_id, $to_body_id, $ship_id, $spy_ids) = @_;
    my $empire = $self->get_empire_by_session($session_id);
	unless ($empire->current_session->check_captcha()) {
		confess [1016,'Needs to solve a captcha.'];
	}
};


1;
