package Lacuna::RPC::Building::Parliament;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';
use Guard qw(guard);

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
    $proposition->cast_vote($empire, $vote);
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}

sub propose_fire_bfg {
    my ($self, $session_id, $building_id, $x, $y, $reason) = @_;
    Lacuna::Verify->new(content=>\$reason, throws=>[1005,'Reason cannot be empty.',$reason])->not_empty;
    Lacuna::Verify->new(content=>\$reason, throws=>[1005,'Reason cannot contain HTML tags or entities.',$reason])->no_tags;
    Lacuna::Verify->new(content=>\$reason, throws=>[1005,'Reason cannot contain profanity.',$reason])->no_profanity;
    my $empire = $self->get_empire_by_session($session_id);
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot vote in parliament.'];
    }
    my $building = $self->get_building($empire, $building_id);
    unless ($building->level >= 30) {
        confess [1013, 'Parliament must be level 30 to propose using the BFG.'];
    }
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({x=>$x, y=>$y},{rows=>1})->single;
    unless (defined $body) {
        confess [1002, 'Could not find the target body.'];
    }
    unless ($body->isa('Lacuna::DB::Result::Map::Body::Planet')) {
        confess [1009, 'Target is not a planet.'];
    }
    $self->body->in_jurisdiction($body);
    my $name = $body->name.' ('.$body->x.','.$body->y.')';
    my $proposition = Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->new({
        type            => 'FireBfg',
        name            => 'Fire BFG at '.$name,
        description     => 'Fire the BFG at '.$name.' from the station named "'.$body->name.'". Reason cited: '.$reason,
        scratch         => { body_id => $body->id },
        proposed_by_id  => $empire->id,
    });
    $proposition->station($body);
    $proposition->proposed_by($empire);
    $proposition->insert;
}


__PACKAGE__->register_rpc_method_names(qw(view_propositions cast_vote));

no Moose;
__PACKAGE__->meta->make_immutable;

