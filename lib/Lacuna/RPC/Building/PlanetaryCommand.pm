package Lacuna::RPC::Building::PlanetaryCommand;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/planetarycommand';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::PlanetaryCommand';
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id, skip_offline => 1);
    my $out = $orig->($self, $empire, $building);
    $out->{planet} = $building->body->get_status($empire);
    $out->{next_colony_cost} = $empire->next_colony_cost;
    return $out;
};

__PACKAGE__->register_rpc_method_names(qw(view_plans));


no Moose;
__PACKAGE__->meta->make_immutable;

