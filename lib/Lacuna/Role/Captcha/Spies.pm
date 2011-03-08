package Lacuna::Role::Captcha::Spies;

use Moose::Role;

before 'assign' => sub {
	my ($self) = @_;
	my $empire = $self->empire;
	unless ($empire->current_session->check_captcha()) {
		confess [1016,'Needs to solve a captcha.'];
	}
};


1;
