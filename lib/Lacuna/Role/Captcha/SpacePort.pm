package Lacuna::Role::Captcha::SpacePort;

use Moose::Role;

before 'send_fleet' => sub {
    my ($self, $session_id, $ship_ids, $target_params) = @_;
	my $empire = $self->body->empire;
	$empire->current_session->check_captcha();
};

1;
