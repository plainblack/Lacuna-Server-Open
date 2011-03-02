package Lacuna::Role::Captcha::Ships;

use Moose::Role;

before 'can_send_to_target' => sub {
    my ($self, $target) = @_;
	my $empire = $self->body->empire;
	$empire->current_session->check_captcha();
};

1;
