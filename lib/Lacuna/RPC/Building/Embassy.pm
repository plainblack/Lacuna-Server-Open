package Lacuna::RPC::Building::Embassy;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';
use Guard qw(guard);

use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);
use Lacuna::Verify;

sub app_url {
    return '/embassy';
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id, skip_offline => 1);
    my $out = $orig->($self, $empire, $building);
    my $alliance = eval{$building->alliance};
    if (defined $alliance) {
        $out->{alliance_status} = $alliance->get_status;
    }
    return $out;
};

sub model_class {
    return 'Lacuna::DB::Result::Building::Embassy';
}

sub assign_alliance_leader {
    my ($self, $session_id, $building_id, $empire_id, $message) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    unless ($empire_id) {
        confess [1002, 'You must specify which empire you want to take over leadership.'];
    }
    my $new_leader = Lacuna->db->resultset('Empire')->find($empire_id);
    unless (defined $new_leader) {
        confess [1002, 'The empire you specified to take over as leader does not exist.'];
    }
    $building->assign_alliance_leader($new_leader);
    return {
        status          => $self->format_status($empire, $building->body),
        alliance        => $building->alliance->get_status,
    };
}

sub create_alliance {
    my ($self, $session_id, $building_id, $name) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $alliance = $building->create_alliance($name);
    return {
        status          => $self->format_status($empire, $building->body),
        alliance        => $alliance->get_status,
    };
}

sub get_alliance_status {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    return {
        status          => $self->format_status($empire, $building->body),
        alliance        => $building->get_alliance_status,
    };
}

sub dissolve_alliance {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $building->dissolve_alliance;
    return {
        status          => $self->format_status($empire, $building->body),
    };
}

sub leave_alliance {
    my ($self, $session_id, $building_id, $message) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $building->leave_alliance($message);
    return {
        status          => $self->format_status($empire, $building->body),
    };
}

sub expel_member {
    my ($self, $session_id, $building_id, $member_id, $message) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $member = Lacuna->db->resultset('Empire')->find($member_id);
    $building->expel_member($member, $message);
    return $self->get_alliance_status($empire, $building);
}

sub accept_invite {
    my ($self, $session_id, $building_id, $invite_id, $message) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    unless ($invite_id) {
        confess [1002, 'You must specify an invite id.'];
    }
    my $invite = Lacuna->db->resultset('AllianceInvite')->find($invite_id);
    unless (defined $invite) {
        confess [1002, 'Invitation not found.'];
    }
    my $cache = Lacuna->cache;
    if ($cache->get('join_alliance_lock', $empire->id)) {
        confess [1010, 'You cannot join an alliance more than once in a 24 hour period. Please wait 24 hours and try again.'];
    }
    $building->accept_invite($invite, $message);
    $cache->set('join_alliance_lock', $empire->id, 1, 60 * 60 * 24);
    return $self->get_alliance_status($empire, $building);
}

sub reject_invite {
    my ($self, $session_id, $building_id, $invite_id, $message) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    unless ($invite_id) {
        confess [1002, 'You must specify an invite id.'];
    }
    my $invite = Lacuna->db->resultset('AllianceInvite')->find($invite_id);
    unless (defined $invite) {
        confess [1002, 'Invitation not found.'];
    }
    $building->reject_invite($invite, $message);
    return {
        status          => $self->format_status($empire, $building->body),
    };
}

sub withdraw_invite {
    my ($self, $session_id, $building_id, $invite_id, $message) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    unless ($invite_id) {
        confess [1002, 'You must specify an invite id.'];
    }
    my $invite = Lacuna->db->resultset('AllianceInvite')->find($invite_id);
    unless (defined $invite) {
        confess [1002, 'Invitation not found.'];
    }
    $building->withdraw_invite($invite, $message);
    return {
        status          => $self->format_status($empire, $building->body),
    };
}

sub send_invite {
    my ($self, $session_id, $building_id, $empire_id, $message) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    unless ($empire_id) {
        confess [1002, 'You must specify which empire you want to invite.'];
    }
    my $invitee = Lacuna->db->resultset('Empire')->find($empire_id);
    unless (defined $invitee) {
        confess [1002, 'The empire you specified to invite does not exist.'];
    }
    $building->send_invite($invitee, $message);
    return {
        status          => $self->format_status($empire, $building->body),
    };
}

sub get_pending_invites {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    return {
        invites         => $building->get_pending_invites,
        status          => $self->format_status($empire, $building->body),
    };
}

sub get_my_invites {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    return {
        invites         => $building->get_my_invites,
        status          => $self->format_status($empire, $building->body),
    };
}


sub update_alliance {
    my ($self, $session_id, $building_id, $params) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $alliance = $building->update_alliance($params);
    return {
        alliance        => $alliance->get_status,
        status          => $self->format_status($empire, $building->body),
    };
}

sub view_stash {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $body = $building->body;
    my %stored;
    foreach my $resource ('water','energy',FOOD_TYPES,ORE_TYPES) {
        $stored{$resource} = $body->type_stored($resource);
    }
    return {
        stash           => $building->alliance->stash || {},
        status          => $self->format_status($empire, $body),
        max_exchange_size   => $building->max_exchange_size,
        exchanges_remaining_today   => $building->exchanges_remaining_today,
        stored          => \%stored,
    };
}

sub donate_to_stash {
    my ($self, $session_id, $building_id, $donation) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $building->alliance->donate($building->body, $donation);
    return $self->view_stash($empire, $building);
}

sub exchange_with_stash {
    my ($self, $session_id, $building_id, $donation, $request) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $building->exchange_with_stash($donation, $request);
    return $self->view_stash($empire, $building);
}

### Methods moved from Parliament

# View all laws by this alliance.
#
sub view_laws {
    my ($self, $session_id, $building_id, $filter) = @_;

    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $alliance = $empire->alliance;
    confess [1002, 'You are not in an alliance.'] if not $alliance;

    my @out;
    my $laws_rs = $alliance->laws;
    while (my $law = $laws_rs->next) {
        push @out, $law->get_status;
    }
    return {
        status          => $self->format_status($empire, $building->body),
        laws            => \@out,
    };
}

sub view_propositions {
    my ($self, $session_id, $building_id, $filter) = @_;

    my $empire   = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $alliance = $empire->alliance;
    confess [1002, 'You are not in an alliance.'] if not $alliance;

    my @out;
    my $propositions = $alliance->propositions->search({ status => 'Pending'});
    if ($filter and $filter->{station_id}) {
        $propositions = $propositions->search({station_id => $filter->{station_id}});
    }
    if ($filter and $filter->{zone}) {
        $propositions = $propositions->search({zone => $filter->{zone}});
    }
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

    my $empire   = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);

    my $cache = Lacuna->cache;
    my $lock = 'vote_lock_'.$empire->id;
    if ($cache->get($lock, $proposition_id)) {
        confess [1013, 'You already have a vote in process for this proposition.'];
    }
    $cache->set($lock,$proposition_id,1,5);
    my $guard = guard {$cache->delete($lock,$proposition_id);};
    my $proposition = Lacuna->db->resultset('Proposition')->find($proposition_id);
    unless (defined $proposition) {
        confess [1002, 'Proposition not found.'];
    }
    $proposition->cast_vote($empire, $vote);
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}

sub propose_writ {
    my ($self, $session_id, $building_id, $title, $writ) = @_;

    my $empire   = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);

    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot create propositions.'];
    }
    if ($building->level < 4) {
        confess [1013, 'Embassy must be level 4 to propose a writ.',4];
    }
    Lacuna::Verify->new(content=>\$title, throws=>[1005,'Title cannot be empty.',$title])->not_empty;
    Lacuna::Verify->new(content=>\$title, throws=>[1005,'Title cannot contain any of these characters: {}<>&;@',$title])->no_restricted_chars;
    Lacuna::Verify->new(content=>\$title, throws=>[1005,'Title must be less than 30 characters.',$title])->length_lt(30);
    Lacuna::Verify->new(content=>\$title, throws=>[1005,'Title cannot contain profanity.',$title])->no_profanity;
    Lacuna::Verify->new(content=>\$writ, throws=>[1005,'Writ cannot be empty.',$writ])->not_empty;
    Lacuna::Verify->new(content=>\$writ, throws=>[1005,'Writ cannot contain HTML tags or entities.',$writ])->no_tags;
    Lacuna::Verify->new(content=>\$writ, throws=>[1005,'Writ cannot contain profanity.',$writ])->no_profanity;

    my $proposition = Lacuna->db->resultset('Proposition')->new({
        type            => 'EnactWrit',
        name            => $title,
        description     => $writ,
        proposed_by_id  => $empire->id,
        alliance_id     => $empire->alliance_id,
    });
    $proposition->alliance($empire->alliance);
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}


sub propose_repeal_law {
    my ($self, $session_id, $building_id, $law_id) = @_;

    my $empire   = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);   
    
    confess [1015, 'Sitters cannot create propositions.'] if $empire->current_session->is_sitter;
    confess [1013, 'Embassy must be level 5 to repeal a law.',5] if $building->level < 5;
    confess [1002, 'Must specify a law id to repeal.'] unless $law_id;

    my $law = $empire->alliance->laws->find($law_id);
    confess [1002, 'Could not find the law.'] unless defined $law;
    
    my $proposition = Lacuna->db->resultset('Proposition')->new({
        type            => 'RepealLaw',
        name            => 'Repeal '.$law->name,
        description     => 'Repeal the law described as: '.$law->description,
        scratch         => { law_id => $law->id },
        proposed_by_id  => $empire->id,
        alliance_id     => $empire->alliance_id,
    });
    $proposition->alliance($empire->alliance);
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}


sub get_stars_in_jurisdiction {
    my ($self, $session_id, $building_id, $zone) = @_;

    my $empire   = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my @out;
    my $stars = Lacuna->db->resultset('Map::Star')->search({
        alliance_id => $empire->alliance_id,
        influence  => {'>=' => 50},
    },{
        order_by        => 'name'
    });
    if ($zone) {
        $stars = $stars->search({
            zone        => $zone,
        });
    }

    while (my $star = $stars->next) {
        push @out, $star->get_status;
    }
    return {
        status          => $self->format_status($empire, $building->body),
        stars           => \@out,
    };
}

sub get_bodies_for_star_in_jurisdiction {
    my ($self, $session_id, $building_id, $star_id) = @_;

    my $empire   = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);

    confess [1002, 'You have to specify a star id.'] unless $star_id;
    my ($star) = Lacuna->db->resultset('Map::Star')->search({
        id              => $star_id,
        alliance_id     => $empire->alliance_id,
        influence  => {'>=' => 50},
    });
    confess [1009, 'That star is not in your jurisdiction.'] unless $star;

    my @out;
    my $bodies = $star->bodies;
    while (my $body = $bodies->next) {
        push @out, $body->get_status($empire);
    }
    return {
        status          => $self->format_status($empire, $building->body),
        bodies          => \@out,
    };
}

sub get_excavators_for_star_in_jurisdiction {
    my ($self, $session_id, $building_id, $star_id) = @_;

    my $empire   = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);

    confess [1002, 'You have to specify a star id.'] unless $star_id;
    my ($star) = Lacuna->db->resultset('Map::Star')->search({
        id              => $star_id,
        alliance_id     => $empire->alliance_id,
        influence  => {'>=' => 50},
    });
    confess [1009, 'That star is not in your jurisdiction.'] unless $star;

    my $excavators = Lacuna->db->resultset('Excavator')->search({
        'body.star_id'  => $star_id,
    },{
        prefetch => ['body', 'planet'],
    });
    
    my @out;
    while (my $excavator = $excavators->next) {
        push @out, {
            id          => $excavator->id,
            empire      => {
                name    => $excavator->planet->empire->name,
                id      => $excavator->planet->empire->id,
            }
        };
    }
    return {
        status          => $self->format_status($empire, $building->body),
        platforms       => \@out,
    };
}

sub get_mining_platforms_for_star_in_jurisdiction {
    my ($self, $session_id, $building_id, $star_id) = @_;

    my $empire   = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);

    confess [1002, 'You have to specify a star id.'] unless $star_id;
    my ($star) = Lacuna->db->resultset('Map::Star')->search({
        id              => $star_id,
        alliance_id     => $empire->alliance_id,
        influence  => {'>=' => 50},
    });
    confess [1009, 'That star is not in your jurisdiction.'] unless $star;

    my $platforms = Lacuna->db->resultset('MiningPlatforms')->search({
        'asteroid.star_id'  => $star_id,
    },{
        prefetch => ['asteroid','planet'],
    });
    
    my @out;
    while (my $platform = $platforms->next) {
        push @out, {
            id          => $platform->id,
            empire      => {
                name    => $platform->planet->empire->name,
                id      => $platform->planet->empire->id,
            }
        };
    }
    return {
        status          => $self->format_status($empire, $building->body),
        platforms       => \@out,
    };
}

sub propose_focus_influence_on_star {
    my ($self, $session_id, $building_id, $station_id, $star_id) = @_;

    confess [666, 'Not implemented yet'];
}

sub propose_rename_star {
    my ($self, $session_id, $building_id, $star_id, $star_name) = @_;

    my $empire   = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);

    confess [1015, 'Sitters cannot create propositions.'] if $empire->current_session->is_sitter;
    confess [1013, 'Embassy must be level 8 to rename a star.',8] if $building->level < 8;
    confess [1002, 'Must specify a star id to rename.'] if not $star_id;
    my ($star) = Lacuna->db->resultset('Map::Star')->search({
        id              => $star_id,
        alliance_id     => $empire->alliance_id,
        influence  => {'>=' => 50},
    });
    confess [1009, 'That star is not in your jurisdiction.'] unless $star;
    
    Lacuna::Verify->new(content=>\$star_name, throws=>[1000,'Name not available.',$star_name])
        ->length_gt(2)
        ->length_lt(31)
        ->no_restricted_chars
        ->no_profanity
        ->no_padding
        ->not_ok(Lacuna->db->resultset('Map::Star')->search({name=>$star_name, 'id'=>{'!='=>$star->id}})->count); # name available

    my $proposition = Lacuna->db->resultset('Proposition')->new({
        type            => 'RenameStar',
        name            => 'Rename '.$star->name,
        description     => 'Rename {Starmap '.$star->x.' '.$star->y.' '.$star->name.'} to '.$star_name.'.',
        scratch         => { star_id => $star->id, name => $star_name },
        proposed_by_id  => $empire->id,
        alliance_id     => $empire->alliance_id,
    });
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}

sub propose_broadcast_on_network19 {
    my ($self, $session_id, $building_id, $message) = @_;

    my $empire   = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);

    confess [1015, 'Sitters cannot create propositions.'] if $empire->current_session->is_sitter;
    confess [1013, 'Embassy must be level 9 to propose a broadcast.',9] if $building->level < 9;
    
    Lacuna::Verify->new(content=>\$message, throws=>[1005,'Message cannot be empty.',$message])->not_empty;
    Lacuna::Verify->new(content=>\$message, throws=>[1005,'Message cannot contain any of these characters: {}<>&;@',$message])->no_restricted_chars;
    Lacuna::Verify->new(content=>\$message, throws=>[1005,'Message must be less than 141 characters.',$message])->length_lt(141);
    Lacuna::Verify->new(content=>\$message, throws=>[1005,'Message cannot contain profanity.',$message])->no_profanity;

    my $proposition = Lacuna->db->resultset('Proposition')->new({
        type            => 'BroadcastOnNetwork19',
        name            => 'Broadcast On Network 19',
        description     => 'Broadcast the following message on Network 19: '.$message,
        scratch         => { message => $message },
        proposed_by_id  => $empire->id,
        alliance_id     => $empire->alliance_id,
        zone            => $building->body->zone,
    });
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}

# How many members can this alliance support?
#
sub max_members {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $leader_emp = $empire->alliance->leader;
    my $leader_planets = $leader_emp->planets;
    my @planet_ids;
    while ( my $planet = $leader_planets->next ) {
        push @planet_ids, $planet->id;
    }
    my $embassy = Lacuna->db->resultset('Building')->search(
        { body_id => { in => \@planet_ids }, class => 'Lacuna::DB::Result::Building::Embassy' },
        { order_by => { -desc => 'level' } }
    )->single;
    return ( $building->level >= $embassy->level ) ? 2 * $building->level : 2 * $embassy->level;
}

sub propose_induct_member {
    my ($self, $session_id, $building_id, $empire_id, $message) = @_;

    my $empire   = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);

    confess [1015, 'Sitters cannot create propositions.'] if $empire->current_session->is_sitter;
    confess [1013, 'Building must be level 10 to induct a new alliance member.',10] if $building->level < 10;
    confess [1002, 'Must specify an empire id to induct a new alliance member.'] unless $empire_id;

    my $alliance    = $empire->alliance;
    my $count       = $alliance->members->count;
    $count         += $alliance->invites->count;
    my $max_members = $self->max_members($session_id, $building_id);

    confess [1009, 'You may only have '.$max_members.' in or invited to this alliance.'] if $count >= $max_members;

    my $invite_empire = Lacuna->db->resultset('Empire')->find($empire_id);
    confess [1002, 'Could not find the empire of the proposed new alliance member.'] if not defined $invite_empire;

    Lacuna::Verify->new(content=>\$message, throws=>[1005,'Message must not contain restricted characters or profanity.', 'message'])
        ->no_tags
        ->no_profanity;
    my $proposition = Lacuna->db->resultset('Proposition')->new({
        type            => 'InductMember',
        name            => 'Induct Member',
        description     => 'Induct {Empire '.$invite_empire->id.' '.$invite_empire->name.'} as a new member of {Alliance '.$alliance->id.' '.$alliance->name.'}.',
        scratch         => { invite_id => $invite_empire->id, message => $message, building_id => $building_id },
        proposed_by_id  => $empire->id,
        alliance_id     => $empire->alliance_id,
    });
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}


sub propose_expel_member {
    my ($self, $session_id, $building_id, $empire_id, $message) = @_;

    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);

    confess [1015, 'Sitters cannot create propositions.'] if $empire->current_session->is_sitter;
    confess [1013, 'Embassy must be level 10 to expel an alliance member.',10] if $building->level < 10;
    confess [1002, 'Must specify an empire id to expel an alliance member.'] unless $empire_id;
    
    my $empire_to_remove = Lacuna->db->resultset('Empire')->find($empire_id);
    confess [1002, 'Could not find the empire of the proposed member to expel.'] unless defined $empire_to_remove;
    confess [1009, 'That empire is not a member of your alliance.'] unless $empire_to_remove->alliance_id == $empire->alliance_id;
    
    my $alliance = $empire->alliance;

    Lacuna::Verify->new(content=>\$message, throws=>[1005,'Message must not contain restricted characters or profanity.', 'message'])
        ->no_tags
        ->no_profanity;
    my $proposition = Lacuna->db->resultset('Proposition')->new({
        type            => 'ExpelMember',
        name            => 'Expel Member',
        description     => 'Expel {Empire '.$empire_to_remove->id.' '.$empire_to_remove->name.'} from {Alliance '.$alliance->id.' '.$alliance->name.'}.',
        scratch         => { empire_id => $empire_to_remove->id, message => $message },
        proposed_by_id  => $empire->id,
        alliance_id     => $empire->alliance_id,
    });
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}

sub propose_elect_new_leader {
    my ($self, $session_id, $building_id, $to_empire_id) = @_;

    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);

    confess [1015, 'Sitters cannot create propositions.'] if $empire->current_session->is_sitter;
    confess [1013, 'Embassy must be level 11 to elect a new alliance leader.',11] if $building->level < 11;
    confess [1002, 'Must specify an empire id to elect a new alliance leader.'] unless $to_empire_id;
    
    my $to_empire = Lacuna->db->resultset('Empire')->find($to_empire_id);
    confess [1002, 'Could not find the empire of the proposed new leader.'] unless defined $to_empire;
    confess [1009, 'That empire is not a member of your alliance.'] if $to_empire->alliance_id != $empire->alliance_id;
    my $alliance = $empire->alliance;

    my $proposition = Lacuna->db->resultset('Proposition')->new({
        type            => 'ElectNewLeader',
        name            => 'Elect New Leader',
        description     => 'Elect {Empire '.$to_empire->id.' '.$to_empire->name.'} as the new leader of {Alliance '.$alliance->id.' '.$alliance->name.'}.',
        scratch         => { empire_id => $to_empire->id },
        proposed_by_id  => $empire->id,
        alliance_id     => $empire->alliance_id,
    });
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}

sub propose_rename_asteroid {
    my ($self, $session_id, $building_id, $asteroid_id, $name) = @_;

    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    confess [1015, 'Sitters cannot create propositions.'] if $empire->current_session->is_sitter;
    confess [1013, 'Embassy must be level 12 to rename an asteroid.',12] if $building->level < 12;
    confess [1002, 'Must specify a asteroid id to rename.'] unless $asteroid_id;

    my $asteroid = Lacuna->db->resultset('Map::Body')->find($asteroid_id);
    confess [1002, 'Could not find the asteroid.'] unless defined $asteroid;

    my ($star) = Lacuna->db->resultset('Map::Star')->search({
        id              => $asteroid->star_id,
        alliance_id     => $empire->alliance_id,
        influence  => {'>=' => 50},
    });
    confess [1009, 'That asteroid is not in your jurisdiction.'] unless $star;

    Lacuna::Verify->new(content=>\$name, throws=>[1000,'Name not available.',$name])
        ->length_gt(2)
        ->length_lt(31)
        ->no_restricted_chars
        ->no_profanity
        ->no_padding
        ->not_ok(Lacuna->db->resultset('Map::Body')->search({name=>$name, 'id'=>{'!='=>$asteroid->id}})->count); # name available

    my $proposition = Lacuna->db->resultset('Proposition')->new({
        type            => 'RenameAsteroid',
        name            => 'Rename '.$asteroid->name,
        description     => 'Rename {Starmap '.$asteroid->x.' '.$asteroid->y.' '.$asteroid->name.'} to '.$name.'.',
        scratch         => { asteroid_id => $asteroid->id, name => $name },
        proposed_by_id  => $empire->id,
        alliance_id     => $empire->alliance_id,
    });
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}

sub propose_rename_uninhabited {
    my ($self, $session_id, $building_id, $planet_id, $name) = @_;

    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    confess [1015, 'Sitters cannot create propositions.'] if $empire->current_session->is_sitter;
    confess [1013, 'Embassy must be level 17 to rename an uninhabited planet.',17] if $building->level < 17;
    confess [1002, 'Must specify a planet id to rename.'] if not $planet_id;

    my $planet = Lacuna->db->resultset('Map::Body')->find($planet_id);
    confess [1002, 'Could not find the planet.'] if not defined $planet;

    my ($star) = Lacuna->db->resultset('Map::Star')->search({
        id              => $planet->star_id,
        alliance_id     => $empire->alliance_id,
        influence  => {'>=' => 50},
    });
    confess [1009, 'That asteroid is not in your jurisdiction.'] unless $star;
    confess [1013, 'That planet is inhabited.'] if $planet->empire_id;

    Lacuna::Verify->new(content=>\$name, throws=>[1000,'Name not available.',$name])
        ->length_gt(2)
        ->length_lt(31)
        ->no_restricted_chars
        ->no_profanity
        ->no_padding
        ->not_ok(Lacuna->db->resultset('Map::Body')->search({name=>$name, 'id'=>{'!='=>$planet->id}})->count); # name available

    my $proposition = Lacuna->db->resultset('Proposition')->new({
        type            => 'RenameUninhabited',
        name            => 'Rename '.$planet->name,
        description     => 'Rename {Starmap '.$planet->x.' '.$planet->y.' '.$planet->name.'} to '.$name.'.',
        scratch         => { planet_id => $planet->id, name => $name },
        proposed_by_id  => $empire->id,
        alliance_id     => $empire->alliance_id,
    });
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}

sub propose_members_only_mining_rights {
    my ($self, $session_id, $building_id, $zone) = @_;

    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    confess [1015, 'Sitters cannot create propositions.'] if $empire->current_session->is_sitter;
    confess [1013, 'Embassy must be level 13 to propose members only mining rights.',13] if $building->level < 13;
    confess [1013, 'You have not specified a zone.'] if not defined $zone;
   
    my $proposition = Lacuna->db->resultset('Proposition')->new({
        type            => 'MembersOnlyMiningRights',
        name            => 'Members Only Mining Rights',
        description     => 'Only members of {Alliance '.$empire->alliance_id.' '.$empire->alliance->name.'} should be allowed to mine asteroids in zone $zone',
        proposed_by_id  => $empire->id,
        alliance_id     => $empire->alliance_id,
    });
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}

sub propose_evict_mining_platform {
    my ($self, $session_id, $building_id, $platform_id) = @_;

    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    confess [1015, 'Sitters cannot create propositions.'] if $empire->current_session->is_sitter;
    confess [1013, 'Parliament must be level 14 to evict a mining platform.',14] if $building->level < 14;
    confess [1002, 'You must specify a mining platform id.'] if not $platform_id;

    my $platform = Lacuna->db->resultset('MiningPlatforms')->find($platform_id);
    confess [1002, 'Platform not found.'] if not defined $platform;

    my ($star) = Lacuna->db->resultset('Map::Star')->search({
        id              => $platform->asteroid->star_id,
        alliance_id     => $empire->alliance_id,
        influence  => {'>=' => 50},
    });
    confess [1009, 'That platform is not in your jurisdiction.'] unless $star;

    my $proposition = Lacuna->db->resultset('Proposition')->new({
        type            => 'EvictMiningPlatform',
        name            => 'Evict '.$platform->planet->empire->name.' Mining Platform',
        description     => 'Evict a mining platform on {Starmap '.$platform->asteroid->x.' '.$platform->asteroid->y.' '.$platform->asteroid->name.'} controlled by {Alliance '.$empire->alliance_id.' '.$empire->alliance->name.'}.',
        scratch         => { platform_id => $platform_id },
        proposed_by_id  => $empire->id,
        alliance_id     => $empire->alliance_id,
    });
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}

sub propose_members_only_colonization {
    my ($self, $session_id, $building_id, $zone) = @_;

    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    confess [1015, 'Sitters cannot create propositions.'] if $empire->current_session->is_sitter;
    confess [1013, 'Embassy must be level 18 to propose members only colonization.',18] if $building->level < 18;
    confess [1013, 'You have not specified a zone.'] if not defined $zone;

    my $proposition = Lacuna->db->resultset('Proposition')->new({
        type            => 'MembersOnlyColonization',
        name            => 'Members Only Colonization',
        description     => 'Only members of {Alliance '.$empire->alliance_id.' '.$empire->alliance->name.'} should be allowed to colonize planets in their jurisdiction in zone '.$zone,
        proposed_by_id  => $empire->id,
        alliance_id     => $empire->alliance_id,
    });
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}

sub propose_neutralize_bhg {
    my ($self, $session_id, $building_id, $zone) = @_;

    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    confess [1015, 'Sitters cannot create propositions.'] if $empire->current_session->is_sitter;
    confess [1013, 'Embassy must be level 23 to propose to neutralize black hole generators.',23] if $building->level < 23;
    confess [1013, 'You have not specified a zone.'] if not defined $zone;

    my $proposition = Lacuna->db->resultset('Proposition')->new({
        type            => 'BHGNeutralized',
        name            => 'BHG Neutralized',
        description     => 'All Black Hole Generators will cease to operate within and on planets in the jurisdiction of {Alliance '.$empire->alliance_id.' '.$empire->alliance->name.'} in zone '.$zone,
        proposed_by_id  => $empire->id,
        alliance_id     => $empire->alliance_id,
    });
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}

sub propose_transfer_station_ownership {
    my ($self, $session_id, $building_id, $to_empire_id) = @_;

    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    confess [1015, 'Sitters cannot create propositions.'] if $empire->current_session->is_sitter;
    confess [1013, 'Embassy must be level 6 to transfer station ownership.',6] if $building->level < 6;
    confess [1002, 'Must specify an empire id to transfer the station to.'] if not $to_empire_id;
    
    my $to_empire = Lacuna->db->resultset('Empire')->find($to_empire_id);
    confess [1002, 'Could not find the empire to transfer the station to.'] if not defined $to_empire;
    confess [1009, 'That empire is not a member of your alliance.'] if $to_empire->alliance_id != $empire->alliance_id;
    confess [1013, 'That empire is an isolationist.'] if $to_empire->is_isolationist;

    my $proposition = Lacuna->db->resultset('Proposition')->new({
        type            => 'TransferStationOwnership',
        name            => 'Transfer Station',
        description     => 'Transfer ownership of {Planet '.$building->body->id.' '.$building->body->name.'} from {Empire '.$building->body->empire_id.' '.$building->body->empire->name.'} to {Empire '.$to_empire->id.' '.$to_empire->name.'}.',
        scratch         => { empire_id => $to_empire->id },
        proposed_by_id  => $empire->id,
        alliance_id     => $empire->alliance_id,
    });
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}

sub propose_fire_bfg {
    my ($self, $session_id, $building_id, $body_id, $reason) = @_;

    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    confess [1015, 'Sitters cannot create propositions.'] if $empire->current_session->is_sitter;
    confess [1013, 'Embassy must be level 25 to propose using the BFG.',25] if $building->level < 25;
    Lacuna::Verify->new(content=>\$reason, throws=>[1005,'Reason cannot be empty.',$reason])->not_empty;
    Lacuna::Verify->new(content=>\$reason, throws=>[1005,'Reason cannot contain HTML tags or entities.',$reason])->no_tags;
    Lacuna::Verify->new(content=>\$reason, throws=>[1005,'Reason cannot contain profanity.',$reason])->no_profanity;
    confess [1002, 'You must specify a body id.'] if not $body_id;

    my $body = Lacuna->db->resultset('Map::Body')->find($body_id);
    confess [1002, 'Could not find the target body.'] if not defined $body;
    confess [1009, 'Target is not a planet.'] if not $body->isa('Lacuna::DB::Result::Map::Body::Planet');

    my $alliance = $body->alliance;
    my ($star) = Lacuna->db->resultset('Map::Star')->search({
        id              => $body->star_id,
        alliance_id     => $empire->alliance_id,
        influence  => {'>=' => 50},
    });
    confess [1009, 'That planet is not in your jurisdiction.'] unless $star;

    my $name = $body->name.' ('.$body->x.','.$body->y.')';
    my $proposition = Lacuna->db->resultset('Proposition')->new({
        type            => 'FireBfg',
        name            => 'Fire BFG at '.$body->name,
        description     => 'Fire the BFG at {Starmap '.$body->x.' '.$body->y.' '.$body->name.'} from {Alliance '.$alliance->id.' '.$alliance->name.'}. Reason cited: '.$reason,
        scratch         => { body_id => $body->id },
        proposed_by_id  => $empire->id,
        alliance_id     => $empire->alliance_id,
    });
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}

__PACKAGE__->register_rpc_method_names(qw(
    exchange_with_stash view_stash donate_to_stash expel_member update_alliance get_pending_invites 
    get_my_invites assign_alliance_leader create_alliance dissolve_alliance send_invite 
    accept_invite withdraw_invite reject_invite leave_alliance get_alliance_status

    view_laws view_propositions cast_vote propose_writ propose_repeal_law get_stars_in_jurisdiction
    get_bodies_for_star_in_jurisdiction get_mining_platforms_for_star_in_jurisdiction
    propose_focus_influence_on_star propose_rename_star propose_broadcast_on_network19
    propose_induct_member propose_expel_member propose_elect_new_leader propose_rename_asteroid
    propose_rename_uninhabited propose_members_only_mining_rights propose_evict_mining_platform
    propose_members_only_colonization propose_neutralize_bhg propose_transfer_station_ownership
    propose_fire_bfg get_excavators_for_star_in_jurisdiction
));

no Moose;
__PACKAGE__->meta->make_immutable;

