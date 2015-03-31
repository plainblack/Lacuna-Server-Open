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
    $out->{next_colony_cost} = $empire->next_colony_cost("colony_ship");
    $out->{next_station_cost} = $empire->next_colony_cost("space_station") if $empire->alliance_id;
    $out->{pod_delay} = $building->pod_delay;
    return $out;
};

sub view_plans {
    my ($self, $session_id, $building_id) = @_;

    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);

    my @out;
    my $sorted_plans = $building->body->sorted_plans;
    foreach my $plan (@$sorted_plans) {
        my $plan_type = $plan->class;
        $plan_type =~ s/Lacuna::DB::Result::Building:://;
        $plan_type =~ s/::/_/g;
        my $item = {
            name                => $plan->class->name,
            plan_type           => $plan_type,
            level               => int($plan->level),
            extra_build_level   => int($plan->extra_build_level),
            quantity            => $plan->quantity,
        };
        push @out, $item;
    }
    return {
        status  => $self->format_status($empire, $building->body),
        plans   => \@out,
    }
}

sub subsidise_pod_cooldown {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);

    unless ($building->is_working) {
        confess [1010, "PCC is not in cooldown mode."];
    }

    unless ($empire->essentia >= 2) {
        confess [1011, "Not enough essentia."];
    }

    $building->finish_work->update;
    $empire->spend_essentia({
        amount  => 2,
        reason  => 'PCC cooldown subsidy after the fact',
    });
    $empire->update;

    return $self->view($empire, $building);
}

__PACKAGE__->register_rpc_method_names(qw(
    subsidise_pod_cooldown
    view_plans
    view_incoming_supply_chains
));



no Moose;
__PACKAGE__->meta->make_immutable;

