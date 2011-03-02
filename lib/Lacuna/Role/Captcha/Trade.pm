package Lacuna::Role::Captcha::Trade;

use Moose::Role;

before 'accept_from_market' => sub {
	my ($self, $session_id, $building_id, $trade_id) = @_;
	my $session = $self->get_session($session_id);
	$session->check_captcha();
};

1;
