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
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    return {
        status          => $self->format_status($session, $building->body),
        survival_odds   => $building->survival_odds,
        graft_odds      => $building->graft_odds,
        grafts          => $building->get_possible_grafts,
        essentia_cost   => 2,
        can_experiment  => eval{ $building->can_experiment } ? 1 : 0,
    };
}

sub run_experiment {
    my ($self, $session_id, $building_id, $spy_id, $affinity) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
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

sub rename_species {
    my ($self, $session_id, $building_id, $me) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    $me->{name} =~ s{^\s+(.*)\s+$}{$1}xms; # remove extra white space
    Lacuna::Verify->new(content=>\$me->{name}, throws=>[1000,'Species name not available.', 'name'])
        ->length_lt(31)
        ->length_gt(2)
        ->not_empty
        ->no_restricted_chars
        ->no_profanity;

    # and the description
    Lacuna::Verify->new(content=>\$me->{description}, throws=>[1005,'Description invalid.', 'description'])
        ->length_lt(1025)
        ->no_restricted_chars
        ->no_profanity if $me->{description};
    return $building->rename_species($me);
}

__PACKAGE__->register_rpc_method_names(qw(prepare_experiment run_experiment rename_species));

no Moose;
__PACKAGE__->meta->make_immutable;

