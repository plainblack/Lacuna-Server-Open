package Lacuna::RPC::Building::Park;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/park';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Park';
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id, skip_offline => 1 });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $out = $orig->($self, $session, $building);
    if ($building->is_working) {
        $out->{party} = {
            seconds_remaining   => $building->work_seconds_remaining,
            happiness           => $building->work->{happiness_from_party},
        };
    }
    else {
        $out->{party}{can_throw} = (eval { $building->can_throw_a_party }) ? 1 : 0;
    }
    return $out;
};

sub throw_a_party {
    my ($self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    $building->throw_a_party;
    return $self->view($session, $building);
}

sub subsidize_party {
    my ($self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;

    unless ($building->is_working) {
        confess [1010, "There is no party."];
    }
 
    unless ($empire->essentia >= 2) {
        confess [1011, "Not enough essentia."];    
    }

    $building->finish_work->update;
    $empire->spend_essentia({
        amount  => 2, 
        reason  => 'party subsidy after the fact',
    });
    $empire->update;

    return $self->view($session, $building);
}

__PACKAGE__->register_rpc_method_names(qw(throw_a_party subsidize_party));


no Moose;
__PACKAGE__->meta->make_immutable;

