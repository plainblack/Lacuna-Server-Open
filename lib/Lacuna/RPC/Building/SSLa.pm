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
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id, skip_offline => 1);
    my $out = $orig->($self, $empire, $building);
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
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $building->can_make_plan($type, $level);
    $building->make_plan($type, $level);
    return $self->view($empire, $building);
}

sub subsidize_plan {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);

    unless ($building->is_working) {
        confess [1010, "There is no plan being built."];
    }
 
    unless ($empire->essentia >= 2) {
        confess [1011, "Not enough essentia."];    
    }

    $building->finish_work->update;
    $empire->spend_essentia(2, 'ssl plan subsidy after the fact');    
    $empire->update;

    return $self->view($empire, $building);
}


__PACKAGE__->register_rpc_method_names(qw(make_plan subsidize_plan));


no Moose;
__PACKAGE__->meta->make_immutable;

