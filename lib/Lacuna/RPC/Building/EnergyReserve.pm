package Lacuna::RPC::Building::EnergyReserve;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/energyreserve';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Energy::Reserve';
}

sub dump {
    my ($self, $session_id, $building_id, $amount) = @_;
	if ($amount <= 0) {
		confess [1009, 'You must specify an amount greater than 0.'];
	}
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $body = $building->body;
    $body->spend_type('energy', $amount);
    $body->add_type('waste', $amount);
    $body->update;
    return {
        status      => $self->format_status($session, $body),
        };
}

__PACKAGE__->register_rpc_method_names(qw(dump));

no Moose;
__PACKAGE__->meta->make_immutable;

