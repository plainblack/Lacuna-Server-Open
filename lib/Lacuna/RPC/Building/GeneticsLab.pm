package Lacuna::RPC::Building::GeneticsLab;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/geneticslab';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::GeneticsLab';
}


sub prepare_experiment {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    return {
        status          => $self->format_status($empire, $building->body),
        survival_odds   => $building->survival_odds,
        graft_odds      => $building->graft_odds,
        grafts          => $building->get_possible_grafts,
        essentia_cost   => 2,
        can_experiment  => eval{ $building->can_experiment } ? 1 : 0,
    };
}

sub run_experiment {
    my ($self, $session_id, $building_id, $spy_id, $affinity) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    unless ($spy_id) {
        confess [1002, 'You have to specify a spy id.'];
    }
    unless ($affinity) {
        confess [1002, 'You have to specify an affinity.'];
    }
    my $spy = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->find($spy_id);
    unless (defined $spy) {
        confess [1002, 'Could not find that spy.'];
    }
    $building->can_experiment;
    my $experiment = $building->experiment($spy, $affinity);
    my $out = $self->prepare_experiment($empire, $building);
    $out->{experiment} = $experiment;
    return $out;
}


__PACKAGE__->register_rpc_method_names(qw(prepare_experiment run_experiment));

no Moose;
__PACKAGE__->meta->make_immutable;

