package Lacuna::RPC::Building::Parliament;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/parliament';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Module::Parliament';
}

sub view_propositions {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my @out;
    my $propositions = $building->propositions->search({ status => 'Pending'});
    while (my $proposition = $propositions->next) {
        $proposition->check_status;
        push @out, $proposition->get_status($empire);
    }
    return {
        status          => $self->format_status($empire, $building->body),
        propositions    => \@out,
    };
}

sub cast_vote {
    my ($self, $session_id, $building_id, $proposition_id, $vote) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot vote in parliament.'];
    }
    my $building = $self->get_building($empire, $building_id);
    my $cache = Lacuna->cache;
    my $lock = 'vote_lock_'.$empire->id;
    if ($cache->get($lock, $proposition_id)) {
        confess [1013, 'You already have a vote in process for this proposition.'];
    }
    $cache->set($lock,$proposition_id,1,5);
    my $guard = guard {$cache->delete($lock,$proposition_id);};
    my $proposition = Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->find($proposition_id);
    unless (defined $proposition) {
        confess [1002, 'Proposition not found.'];
    }
    $proposition->cast_vote($self->empire, $vote);
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}


__PACKAGE__->register_rpc_method_names(qw(view_propositions));

no Moose;
__PACKAGE__->meta->make_immutable;

