package Lacuna::Role::Captcha::Spies;

use Moose::Role;

before 'assign' => sub {
	my ($self) = @_;
	my $empire = $self->empire;
	$empire->current_session->check_captcha();
};


1;
