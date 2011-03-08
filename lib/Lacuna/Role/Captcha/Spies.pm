package Lacuna::Role::Captcha::Spies;

use Moose::Role;

before 'assign' => sub {
	my ($self, $assignment) = @_;
	my $empire = $self->empire();
	my $session = $empire->current_session();
	unless ($session->check_captcha()) {
		confess [1016,'Needs to solve a captcha.'];
	}
};

=pod
sub assign_spy {
    my ($self, $session_id, $building_id, $spy_id, $assignment) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $spy = $building->get_spy($spy_id);
    unless (defined $spy) {
        confess [1002, "Spy not found."];
    }
    my $mission = $spy->assign($assignment);
    return {
        status  => $self->format_status($empire, $building->body),
        mission => $mission,
        spy     => $spy->get_status,
    };
}
=cut


1;
