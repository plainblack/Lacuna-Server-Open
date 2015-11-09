package Lacuna::RPC::Building::SSLa;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/ssla';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::SSLa';
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id, skip_offline => 1 });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $out = $orig->($self, $session, $building);
    $out->{make_plan} = {
        types           => $building->makeable_plans_formatted,
        level_costs     => $building->level_costs_formatted,
        subsidy_cost    => 2,
    };
    if ($building->is_working) {
        $out->{make_plan}{making} = $building->work->{class}->name . ' ('.$building->work->{level}.'+0)';
    }
    return $out;
};


sub make_plan {
    my ($self, $session_id, $building_id, $type, $level) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    $building->can_make_plan($type, $level);
    $building->make_plan($type, $level);
    return $self->view($session, $building);
}

sub subsidize_plan {
    my ($self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;

    unless ($building->is_working) {
        confess [1010, "There is no plan being built."];
    }
 
    unless ($empire->essentia >= 2) {
        confess [1011, "Not enough essentia."];    
    }

    $building->finish_work->update;
    $empire->spend_essentia({
        amount      => 2,
        reason      => 'ssl plan subsidy after the fact',
    });
    $empire->update;

    return $self->view($session, $building);
}


__PACKAGE__->register_rpc_method_names(qw(make_plan subsidize_plan));


no Moose;
__PACKAGE__->meta->make_immutable;

