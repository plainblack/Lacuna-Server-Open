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
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $body = $building->body;
    $body->spend_type('energy', $amount);
    $body->add_type('waste', $amount);
    $body->update;
    return {
        status      => $self->format_status($empire, $body),
        };
}

__PACKAGE__->register_rpc_method_names(qw(dump));

no Moose;
__PACKAGE__->meta->make_immutable;

