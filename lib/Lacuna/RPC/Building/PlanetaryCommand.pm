package Lacuna::RPC::Building::PlanetaryCommand;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

with 'Lacuna::Role::IncomingSupplyChains';

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
    $out->{ore} = $building->body->get_ore_status;
    $out->{food} = $building->body->get_food_status;
    $out->{next_colony_cost} = $empire->next_colony_cost;
    return $out;
};

sub view_plans {
    my ($self, $session_id, $building_id) = @_;

    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $item_hash;
    my $plans = $building->body->plans;
    while (my $plan = $plans->next) {
        my $key = sprintf("%s-%s-%s", $plan->class->name, $plan->level, $plan->extra_build_level);
        $item_hash->{$key} = {
            quantity            => $plan->quantity,
            name                => $plan->class->name,
            level               => $plan->level,
            extra_build_level   => $plan->extra_build_level,
        };
    }
    my $out;
    @{$out} = sort {$a->{name} cmp $b->{name} || $a->{level} <=> $b->{level} || $b->{extra_build_level} <=> $a->{extra_build_level} } values %{$item_hash};

    return {
        status  => $self->format_status($empire, $building->body),
        plans   => $out,
    }
}

__PACKAGE__->register_rpc_method_names(qw(view_plans view_incoming_supply_chains));



no Moose;
__PACKAGE__->meta->make_immutable;

