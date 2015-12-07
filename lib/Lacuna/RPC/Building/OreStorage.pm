package Lacuna::RPC::Building::OreStorage;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';
use Lacuna::Constants qw(ORE_TYPES);

sub app_url {
    return '/orestorage';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Ore::Storage';
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id, skip_offline => 1 });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $out = $orig->($self, $session, $building);
    my %ores;
    my $body = $building->body;
    foreach my $ore (ORE_TYPES) {
        $ores{$ore} = $body->type_stored($ore);
    }
    $out->{ore_stored} = \%ores;
    return $out;
};

sub dump {
    my ($self, $session_id, $building_id, $type, $amount) = @_;
	if ($amount <= 0) {
		confess [1009, 'You must specify an amount greater than 0.'];
	}
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $body = $building->body;
    $body->spend_type($type, $amount);
    $body->add_type('waste', $amount);
    $body->update;
    return {
        status      => $self->format_status($session, $body),
    };
}

__PACKAGE__->register_rpc_method_names(qw(dump));

no Moose;
__PACKAGE__->meta->make_immutable;

