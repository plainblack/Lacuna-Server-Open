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

sub max_members {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $leader_emp = $building->body->alliance->leader;
    my $leader_planets = $leader_emp->planets;
    my @planet_ids;
    while ( my $planet = $leader_planets->next ) {
        push @planet_ids, $planet->id;
    }
    my $embassy = Lacuna->db->resultset('Lacuna::DB::Result::Building')->search(
        { body_id => { in => \@planet_ids }, class => 'Lacuna::DB::Result::Building::Embassy' }, 
        { order_by => { -desc => 'level' } }
    )->first;
    return ( $building->effective_level >= $embassy->effective_level ) ? 2 * $building->effective_level : 2 * $embassy->effective_level;
}

# this is moving to the new location, but keep it available here
# until we're ready to remove it.
*view_propositions = \&Lacuna::RPC::Building::Embassy::view_propositions;

sub get_stars_in_jurisdiction {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my @out;
    my $stars = $building->body->stars->search({},{order_by => "name"});
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
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    unless ($star_id) {
        confess [1002, 'You have to specify a star id.'];
    }
    my $star = $building->body->stars->find($star_id);
    my @out;
    unless ($star) {
        confess [1009, 'That star is not in your jurisdiction.'];
    }
    my $bodies = $star->bodies->search({},{order_by => 'orbit'});
    while (my $body = $bodies->next) {
        push @out, $body->get_status($empire);
    }
    return {
        status          => $self->format_status($empire, $building->body),
        bodies          => \@out,
    };
}

sub get_mining_platforms_for_asteroid_in_jurisdiction {
    my ($self, $session_id, $building_id, $asteroid_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my @out;
    my @star_ids = $building->body->stars->get_column('id')->all;
    unless ($asteroid_id) {
        confess [1002, 'You must specify an asteroid id.'];
    }
    my $asteroid = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($asteroid_id);
    unless (defined $asteroid) {
        confess [1002, 'Asteroid not found.'];
    }
    unless ($asteroid->star->station_id == $building->body_id) {
        confess [1009, 'That asteroid is not in your jurisdiction.'];
    }
    my $platforms = Lacuna->db->resultset('Lacuna::DB::Result::MiningPlatforms')->search({asteroid_id => $asteroid->id});
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

sub view_laws {
    my ($self, $session_id, $body_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')
                ->find($body_id);
    if ($body->isa('Lacuna::DB::Result::Map::Body::Planet::Station')) {
        my @out;
        my $laws = $body->laws;
        while (my $law = $laws->next) {
            push @out, $law->get_status($empire);
        }
        return {
            status          => $self->format_status($empire, $body),
            laws            => \@out,
        };
    }
    else {
        return {
            status => "Not a station",
            laws   => [],
        },
    }
}

# this is moving to the new location, but keep it available here
# until we're ready to remove it.
*cast_vote = \&Lacuna::RPC::Building::Embassy::cast_vote;

sub propose_fire_bfg {
    my ($self, $session_id, $building_id, $body_id, $reason) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot create propositions.'];
    }
    $empire->current_session->check_captcha;
    my $building = $self->get_building($empire, $building_id);
    unless ($building->effective_level >= 25) {
        confess [1013, 'Parliament must be level 25 to propose using the BFG.',25];
    }
    unless ($building->effective_level > 0 and $building->effective_efficiency == 100) {
        confess [1003, "You must have a functional Parliament!"];
    }
    Lacuna::Verify->new(content=>\$reason, throws=>[1005,'Reason cannot be empty.',$reason])->not_empty;
    Lacuna::Verify->new(content=>\$reason, throws=>[1005,'Reason cannot contain HTML tags or entities.',$reason])->no_tags;
    Lacuna::Verify->new(content=>\$reason, throws=>[1005,'Reason cannot contain profanity.',$reason])->no_profanity;
    unless ($body_id) {
        confess [1002, 'You must specify a body id.'];
    }
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($body_id);
    unless (defined $body) {
        confess [1002, 'Could not find the target body.'];
    }
    unless ($body->isa('Lacuna::DB::Result::Map::Body::Planet')) {
        confess [1009, 'Target is not a planet.'];
    }
    $building->body->in_jurisdiction($body);
    my $name = $body->name.' ('.$body->x.','.$body->y.')';
    my $proposition = Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->new({
        type            => 'FireBfg',
        name            => 'Fire BFG at '.$body->name,
        description     => 'Fire the BFG at {Starmap '.$body->x.' '.$body->y.' '.$body->name.'} from {Planet '.$building->body->id.' '.$building->body->name.'}. Reason cited: '.$reason,
        scratch         => { body_id => $body->id },
        proposed_by_id  => $empire->id,
    });
    $proposition->station($building->body);
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}

sub propose_writ {
    my ($self, $session_id, $building_id, $title, $writ) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot create propositions.'];
    }
    my $building = $self->get_building($empire, $building_id);
    unless ($building->effective_level >= 4) {
        confess [1013, 'Parliament must be level 4 to propose a writ.',4];
    }
    unless ($building->effective_level > 0 and $building->effective_efficiency == 100) {
        confess [1003, "You must have a functional Parliament!"];
    }
    Lacuna::Verify->new(content=>\$title, throws=>[1005,'Title cannot be empty.',$title])->not_empty;
    Lacuna::Verify->new(content=>\$title, throws=>[1005,'Title cannot contain any of these characters: {}<>&;@',$title])->no_restricted_chars;
    Lacuna::Verify->new(content=>\$title, throws=>[1005,'Title must be less than 30 characters.',$title])->length_lt(30);
    Lacuna::Verify->new(content=>\$title, throws=>[1005,'Title cannot contain profanity.',$title])->no_profanity;
    Lacuna::Verify->new(content=>\$writ, throws=>[1005,'Writ cannot be empty.',$writ])->not_empty;
    Lacuna::Verify->new(content=>\$writ, throws=>[1005,'Writ cannot contain HTML tags or entities.',$writ])->no_tags;
    Lacuna::Verify->new(content=>\$writ, throws=>[1005,'Writ cannot contain profanity.',$writ])->no_profanity;
    my $proposition = Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->new({
        type            => 'EnactWrit',
        name            => $title,
        description     => $writ,
        proposed_by_id  => $empire->id,
    });
    $proposition->station($building->body);
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
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot create propositions.'];
    }
    my $building = $self->get_building($empire, $building_id);
    unless ($building->effective_level >= 6) {
        confess [1013, 'Parliament must be level 6 to transfer station ownership.',6];
    }
    unless ($building->effective_level > 0 and $building->effective_efficiency == 100) {
        confess [1003, "You must have a functional Parliament!"];
    }
    unless ($to_empire_id) {
        confess [1002, 'Must specify an empire id to transfer the station to.'];
    }
    my $to_empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($to_empire_id);
    unless (defined $to_empire) {
        confess [1002, 'Could not find the empire to transfer the station to.'];
    }
    unless ($to_empire->alliance_id == $empire->alliance_id) {
        confess [1009, 'That empire is not a member of your alliance.'];
    }
    if ($to_empire->is_isolationist) {
        confess [1013, 'That empire is an isolationist.'];
    }
    my $proposition = Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->new({
        type            => 'TransferStationOwnership',
        name            => 'Transfer Station',
        description     => 'Transfer ownership of {Planet '.$building->body->id.' '.$building->body->name.'} from {Empire '.$building->body->empire_id.' '.$building->body->empire->name.'} to {Empire '.$to_empire->id.' '.$to_empire->name.'}.',
        scratch         => { empire_id => $to_empire->id },
        proposed_by_id  => $empire->id,
    });
    $proposition->station($building->body);
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}

sub propose_repeal_law {
    my ($self, $session_id, $building_id, $law_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot create propositions.'];
    }
    my $building = $self->get_building($empire, $building_id);
    unless ($building->effective_level >= 5) {
        confess [1013, 'Parliament must be level 5 to repeal a law.',5];
    }
    unless ($building->effective_level > 0 and $building->effective_efficiency == 100) {
        confess [1003, "You must have a functional Parliament!"];
    }
    unless ($law_id) {
        confess [1002, 'Must specify a law id to repeal.'];
    }
    my $law = $building->body->laws->find($law_id);
    unless (defined $law) {
        confess [1002, 'Could not find the law.'];
    }
    my $proposition = Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->new({
        type            => 'RepealLaw',
        name            => 'Repeal '.$law->name,
        description     => 'Repeal the law described as: '.$law->description,
        scratch         => { law_id => $law->id },
        proposed_by_id  => $empire->id,
    });
    $proposition->station($building->body);
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}

sub propose_rename_star {
    my ($self, $session_id, $building_id, $star_id, $star_name) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot create propositions.'];
    }
    my $building = $self->get_building($empire, $building_id);
    unless ($building->effective_level >= 8) {
        confess [1013, 'Parliament must be level 8 to rename a star.',8];
    }
    unless ($building->effective_level > 0 and $building->effective_efficiency == 100) {
        confess [1003, "You must have a functional Parliament!"];
    }
    unless ($star_id) {
        confess [1002, 'Must specify a star id to rename.'];
    }
    my $star = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->find($star_id);
    unless (defined $star) {
        confess [1002, 'Could not find the star.'];
    }
    unless ($star->station_id == $building->body_id) {
        confess [1009, 'That star is not controlled by this station.'];
    }
    Lacuna::Verify->new(content=>\$star_name, throws=>[1000,'Name not available.',$star_name])
        ->length_gt(2)
        ->length_lt(31)
        ->no_restricted_chars
        ->no_profanity
        ->no_padding
        ->not_ok(Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->search({name=>$star_name, 'id'=>{'!='=>$star->id}})->count); # name available
    my $proposition = Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->new({
        type            => 'RenameStar',
        name            => 'Rename '.$star->name,
        description     => 'Rename {Starmap '.$star->x.' '.$star->y.' '.$star->name.'} to '.$star_name.'.',
        scratch         => { star_id => $star->id, name => $star_name },
        proposed_by_id  => $empire->id,
    });
    $proposition->station($building->body);
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}

sub propose_broadcast_on_network19 {
    my ($self, $session_id, $building_id, $message) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot create propositions.'];
    }
    my $building = $self->get_building($empire, $building_id);
    unless ($building->effective_level >= 9) {
        confess [1013, 'Parliament must be level 9 to propose a broadcast.',9];
    }
    unless ($building->effective_level > 0 and $building->effective_efficiency == 100) {
        confess [1003, "You must have a functional Parliament!"];
    }
    Lacuna::Verify->new(content=>\$message, throws=>[1005,'Message cannot be empty.',$message])->not_empty;
    Lacuna::Verify->new(content=>\$message, throws=>[1005,'Message cannot contain any of these characters: {}<>&;@',$message])->no_restricted_chars;
    Lacuna::Verify->new(content=>\$message, throws=>[1005,'Message must be less than 141 characters.',$message])->length_lt(141);
    Lacuna::Verify->new(content=>\$message, throws=>[1005,'Message cannot contain profanity.',$message])->no_profanity;
    my $proposition = Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->new({
        type            => 'BroadcastOnNetwork19',
        name            => 'Broadcast On Network 19',
        description     => 'Broadcast the following message on Network 19: '.$message,
        scratch         => { message => $message },
        proposed_by_id  => $empire->id,
    });
    $proposition->station($building->body);
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
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot create propositions.'];
    }
    my $building = $self->get_building($empire, $building_id);
    unless ($building->effective_level >= 12) {
        confess [1013, 'Parliament must be level 12 to rename an asteroid.',12];
    }
    unless ($building->effective_level > 0 and $building->effective_efficiency == 100) {
        confess [1003, "You must have a functional Parliament!"];
    }
    unless ($asteroid_id) {
        confess [1002, 'Must specify a asteroid id to rename.'];
    }
    my $asteroid = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($asteroid_id);
    unless (defined $asteroid) {
        confess [1002, 'Could not find the asteroid.'];
    }
    unless ($asteroid->star->station_id == $building->body_id) {
        confess [1009, 'That asteroid is not controlled by this station.'];
    }
    Lacuna::Verify->new(content=>\$name, throws=>[1000,'Name not available.',$name])
        ->length_gt(2)
        ->length_lt(31)
        ->no_restricted_chars
        ->no_profanity
        ->no_padding
        ->not_ok(Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({name=>$name, 'id'=>{'!='=>$asteroid->id}})->count); # name available
    my $proposition = Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->new({
        type            => 'RenameAsteroid',
        name            => 'Rename '.$asteroid->name,
        description     => 'Rename {Starmap '.$asteroid->x.' '.$asteroid->y.' '.$asteroid->name.'} to '.$name.'.',
        scratch         => { asteroid_id => $asteroid->id, name => $name },
        proposed_by_id  => $empire->id,
    });
    $proposition->station($building->body);
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
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot create propositions.'];
    }
    my $building = $self->get_building($empire, $building_id);
    unless ($building->effective_level >= 17) {
        confess [1013, 'Parliament must be level 17 to rename an uninhabited planet.',17];
    }
    unless ($building->effective_level > 0 and $building->effective_efficiency == 100) {
        confess [1003, "You must have a functional Parliament!"];
    }
    unless ($planet_id) {
        confess [1002, 'Must specify a planet id to rename.'];
    }
    my $planet = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($planet_id);
    unless (defined $planet) {
        confess [1002, 'Could not find the planet.'];
    }
    unless ($planet->star->station_id == $building->body_id) {
        confess [1009, 'That planet is not controlled by this station.'];
    }
    if ($planet->empire_id) {
        confess [1013, 'That planet is inhabited.'];
    }
    Lacuna::Verify->new(content=>\$name, throws=>[1000,'Name not available.',$name])
        ->length_gt(2)
        ->length_lt(31)
        ->no_restricted_chars
        ->no_profanity
        ->no_padding
        ->not_ok(Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({name=>$name, 'id'=>{'!='=>$planet->id}})->count); # name available
    my $proposition = Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->new({
        type            => 'RenameUninhabited',
        name            => 'Rename '.$planet->name,
        description     => 'Rename {Starmap '.$planet->x.' '.$planet->y.' '.$planet->name.'} to '.$name.'.',
        scratch         => { planet_id => $planet->id, name => $name },
        proposed_by_id  => $empire->id,
    });
    $proposition->station($building->body);
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}

sub propose_members_only_mining_rights {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot create propositions.'];
    }
    my $building = $self->get_building($empire, $building_id);
    unless ($building->effective_level >= 13) {
        confess [1013, 'Parliament must be level 13 to propose members only mining rights.',13];
    }
    unless ($building->effective_level > 0 and $building->effective_efficiency == 100) {
        confess [1003, "You must have a functional Parliament!"];
    }
    my $proposition = Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->new({
        type            => 'MembersOnlyMiningRights',
        name            => 'Members Only Mining Rights',
        description     => 'Only members of {Alliance '.$building->body->alliance_id.' '.$building->body->alliance->name.'} should be allowed to mine asteroids in the jurisdiction of {Starmap '.$building->body->x.' '.$building->body->y.' '.$building->body->name.'}.',
        proposed_by_id  => $empire->id,
    });
    $proposition->station($building->body);
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}

sub propose_members_only_excavation {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot create propositions.'];
    }
    my $building = $self->get_building($empire, $building_id);
    unless ($building->effective_level >= 20) {
        confess [1013, 'Parliament must be level 20 to propose members only excavation rights.',20];
    }
    unless ($building->effective_level > 0 and $building->effective_efficiency == 100) {
        confess [1003, "You must have a functional Parliament!"];
    }
    my $proposition = Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->new({
        type            => 'MembersOnlyExcavation',
        name            => 'Members Only Excavation',
        description     => 'Only members of {Alliance '.$building->body->alliance_id.' '.$building->body->alliance->name.'} should be allowed to excavate bodies in the jurisdiction of {Starmap '.$building->body->x.' '.$building->body->y.' '.$building->body->name.'}.',
        proposed_by_id  => $empire->id,
    });
    $proposition->station($building->body);
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}

sub propose_members_only_colonization {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot create propositions.'];
    }
    my $building = $self->get_building($empire, $building_id);
    unless ($building->effective_level >= 18) {
        confess [1013, 'Parliament must be level 18 to propose members only colonization.',18];
    }
    unless ($building->effective_level > 0 and $building->effective_efficiency == 100) {
        confess [1003, "You must have a functional Parliament!"];
    }
    my $proposition = Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->new({
        type            => 'MembersOnlyColonization',
        name            => 'Members Only Colonization',
        description     => 'Only members of {Alliance '.$building->body->alliance_id.' '.$building->body->alliance->name.'} should be allowed to colonize planets in the jurisdiction of {Starmap '.$building->body->x.' '.$building->body->y.' '.$building->body->name.'}.',
        proposed_by_id  => $empire->id,
    });
    $proposition->station($building->body);
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}

sub propose_neutralize_bhg {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot create propositions.'];
    }
    my $building = $self->get_building($empire, $building_id);
    unless ($building->effective_level >= 23) {
        confess [1013, 'Parliament must be level 23 to propose to neutralize black hole generators.',23];
    }
    unless ($building->effective_level > 0 and $building->effective_efficiency == 100) {
        confess [1003, "You must have a functional Parliament!"];
    }
    my $proposition = Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->new({
        type            => 'BHGNeutralized',
        name            => 'BHG Neutralized',
        description     => 'All Black Hole Generators will cease to operate within and on planets in the jurisdiction of {Starmap '.$building->body->x.' '.$building->body->y.' '.$building->body->name.'}.',
        proposed_by_id  => $empire->id,
    });
    $proposition->station($building->body);
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
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot create propositions.'];
    }
    my $building = $self->get_building($empire, $building_id);
    unless ($building->effective_level >= 14) {
        confess [1013, 'Parliament must be level 14 to evict a mining platform.',14];
    }
    unless ($building->effective_level > 0 and $building->effective_efficiency == 100) {
        confess [1003, "You must have a functional Parliament!"];
    }
    unless ($platform_id) {
        confess [1002, 'You must specify a mining platform id.'];
    }
    my $platform = Lacuna->db->resultset('Lacuna::DB::Result::MiningPlatforms')->find($platform_id);
    unless (defined $platform) {
        confess [1002, 'Platform not found.'];
    }
    unless ($platform->asteroid->star->station_id == $building->body_id) {
        confess [1009, 'That platform is not in your jurisdiction.'];
    }
    my $proposition = Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->new({
        type            => 'EvictMiningPlatform',
        name            => 'Evict '.$platform->planet->empire->name.' Mining Platform',
        description     => 'Evict a mining platform on {Starmap '.$platform->asteroid->x.' '.$platform->asteroid->y.' '.$platform->asteroid->name.'} controlled by {Empire '.$platform->planet->empire_id.' '.$platform->planet->empire->name.'}.',
        scratch         => { platform_id => $platform_id },
        proposed_by_id  => $empire->id,
    });
    $proposition->station($building->body);
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}

sub propose_evict_excavator {
    my ($self, $session_id, $building_id, $excav_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot create propositions.'];
    }
    my $building = $self->get_building($empire, $building_id);
    unless ($building->effective_level >= 21) {
        confess [1013, 'Parliament must be level 21 to evict an excavator.',21];
    }
    unless ($building->effective_level > 0 and $building->effective_efficiency == 100) {
        confess [1003, "You must have a functional Parliament!"];
    }
    unless ($excav_id) {
        confess [1002, 'You must specify an excavator id.'];
    }
    my $excav = Lacuna->db->resultset('Lacuna::DB::Result::Excavators')->find($excav_id);
    unless (defined $excav) {
        confess [1002, 'Excavator not found.'];
    }
    unless ($excav->body->star->station_id == $building->body_id) {
        confess [1009, 'That excavator is not in your jurisdiction.'];
    }
    my $proposition = Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->new({
        type            => 'EvictExcavator',
        name            => 'Evict '.$excav->planet->empire->name.' Excavator',
        description     => 'Evict a excavator on {Starmap '.$excav->body->x.' '.$excav->body->y.' '.$excav->body->name.'} controlled by {Empire '.$excav->planet->empire_id.' '.$excav->planet->empire->name.'}.',
        scratch         => { excav_id => $excav_id },
        proposed_by_id  => $empire->id,
    });
    $proposition->station($building->body);
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
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot create propositions.'];
    }
    my $building = $self->get_building($empire, $building_id);
    unless ($building->effective_level >= 11) {
        confess [1013, 'Parliament must be level 11 to elect a new alliance leader.',11];
    }
    unless ($building->effective_level > 0 and $building->effective_efficiency == 100) {
        confess [1003, "You must have a functional Parliament!"];
    }
    unless ($to_empire_id) {
        confess [1002, 'Must specify an empire id to elect a new alliance leader.'];
    }
    my $to_empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($to_empire_id);
    unless (defined $to_empire) {
        confess [1002, 'Could not find the empire of the proposed new leader.'];
    }
    unless ($to_empire->alliance_id == $empire->alliance_id) {
        confess [1009, 'That empire is not a member of your alliance.'];
    }
    my $proposition = Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->new({
        type            => 'ElectNewLeader',
        name            => 'Elect New Leader',
        description     => 'Elect {Empire '.$to_empire->id.' '.$to_empire->name.'} as the new leader of {Alliance '.$building->body->alliance_id.' '.$building->body->alliance->name.'}.',
        scratch         => { empire_id => $to_empire->id },
        proposed_by_id  => $empire->id,
    });
    $proposition->station($building->body);
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}

sub propose_induct_member {
    my ($self, $session_id, $building_id, $empire_id, $message) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot create propositions.'];
    }
    my $building = $self->get_building($empire, $building_id);
    unless ($building->effective_level >= 10) {
        confess [1013, 'Parliament must be level 10 to induct a new alliance member.',10];
    }
    unless ($building->effective_level > 0 and $building->effective_efficiency == 100) {
        confess [1003, "You must have a functional Parliament!"];
    }
    my $alliance = $building->body->alliance;
    my $count = $alliance->members->count;
    $count += $alliance->invites->count;
    my $max_members = $self->max_members($session_id, $building_id);
    if ($count >= $max_members ) {
        confess [1009, 'You may only have '.$max_members.' in or invited to this alliance.'];
    }
    unless ($empire_id) {
        confess [1002, 'Must specify an empire id to induct a new alliance member.'];
    }
    my $invite_empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($empire_id);
    unless (defined $invite_empire) {
        confess [1002, 'Could not find the empire of the proposed new alliance member.'];
    }
    Lacuna::Verify->new(content=>\$message, throws=>[1005,'Message must not contain restricted characters or profanity.', 'message'])
        ->no_tags
        ->no_profanity;
    my $proposition = Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->new({
        type            => 'InductMember',
        name            => 'Induct Member',
        description     => 'Induct {Empire '.$invite_empire->id.' '.$invite_empire->name.'} as a new member of {Alliance '.$building->body->alliance_id.' '.$building->body->alliance->name.'}.',
        scratch         => { invite_id => $invite_empire->id, message => $message, building_id => $building_id },
        proposed_by_id  => $empire->id,
    });
    $proposition->station($building->body);
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
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot create propositions.'];
    }
    my $building = $self->get_building($empire, $building_id);
    unless ($building->effective_level >= 10) {
        confess [1013, 'Parliament must be level 10 to expel an alliance member.',10];
    }
    unless ($building->effective_level > 0 and $building->effective_efficiency == 100) {
        confess [1003, "You must have a functional Parliament!"];
    }
    unless ($empire_id) {
        confess [1002, 'Must specify an empire id to expel an alliance member.'];
    }
    my $empire_to_remove = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($empire_id);
    unless (defined $empire_to_remove) {
        confess [1002, 'Could not find the empire of the proposed member to expel.'];
    }
    unless ($empire_to_remove->alliance_id == $empire->alliance_id) {
        confess [1009, 'That empire is not a member of your alliance.'];
    }
    Lacuna::Verify->new(content=>\$message, throws=>[1005,'Message must not contain restricted characters or profanity.', 'message'])
        ->no_tags
        ->no_profanity;
    my $proposition = Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->new({
        type            => 'ExpelMember',
        name            => 'Expel Member',
        description     => 'Expel {Empire '.$empire_to_remove->id.' '.$empire_to_remove->name.'} from {Alliance '.$building->body->alliance_id.' '.$building->body->alliance->name.'}.',
        scratch         => { empire_id => $empire_to_remove->id, message => $message },
        proposed_by_id  => $empire->id,
    });
    $proposition->station($building->body);
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}

sub propose_taxation {
    my ($self, $session_id, $building_id, $taxes) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot create propositions.'];
    }
    my $building = $self->get_building($empire, $building_id);
    unless ($building->effective_level >= 15) {
        confess [1013, 'Parliament must be level 15 to propose taxation.',15];
    }
    unless ($building->effective_level > 0 and $building->effective_efficiency == 100) {
        confess [1003, "You must have a functional Parliament!"];
    }
    unless ($taxes =~ /^\d+$/ && $taxes > 0 )
    {
        confess [1009, 'Taxes must be an integer greater than 0.'];
    }
    my $proposition = Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->new({
        type            => 'Taxation',
        name            => 'Tax of '.$taxes.' resources per day',
        description     => 'Implement a tax of '.$taxes. ' resources per day for all empires in the jurisdiction of {Starmap '.$building->body->x.' '.$building->body->y.' '.$building->body->name.'}.',
        scratch         => { taxes => $taxes },
        proposed_by_id  => $empire->id,
    });
    $proposition->station($building->body);
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}

sub propose_foreign_aid {
    my ($self, $session_id, $building_id, $planet_id, $resources) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot create propositions.'];
    }
    my $building = $self->get_building($empire, $building_id);
    unless ($building->effective_level >= 16) {
        confess [1013, 'Parliament must be level 16 to send out foreign aid packages.',16];
    }
    unless ($building->effective_level > 0 and $building->effective_efficiency == 100) {
        confess [1003, "You must have a functional Parliament!"];
    }
    unless ($planet_id) {
        confess [1002, 'You must specify a planet id.'];
    }
    my $planet = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($planet_id);
    unless (defined $planet) {
        confess [1002, 'Could not find the planet.'];
    }
    unless ($planet->star->station_id == $building->body_id) {
        confess [1009, 'That planet is not in the jurisdiction of this station.'];
    }

    my $cost = 2 * $resources;
    my @types = qw( energy food ore water );
    my @costs = @types;
    my %cost;
    # mostly even distribution of resources
    while ( my $type = shift @costs ) {
        my $cost_per_resource = int($cost / (scalar @costs + 1));
        $cost{$type} = $cost_per_resource;
        $cost -= $cost_per_resource;
    }
    for my $cost ( @types ) {
        my $method = "${cost}_stored";
        unless ( $building->body->$method >= $cost{$cost} ) {
            confess [1007, "The station does not have enough $cost stored."];
        }
    }
    my $proposition = Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->new({
        type            => 'Foreign Aid',
        name            => 'Foreign Aid for '.$planet->name.'.',
        description     => 'Send a foreign aid package of '.$resources.' resources to {Starmap '.$planet->x, $planet->y, $planet->name.'} (total cost '.2*$resources.' resources).',
        scratch         => {
            planet_id => $planet->id,
            resources => $resources,
            energy_cost => $cost{energy},
            food_cost => $cost{food},
            ore_cost => $cost{ore},
            water_cost => $cost{water},
        },
        proposed_by_id  => $empire->id,
    });
    $proposition->station($building->body);
    $proposition->proposed_by($empire);
    $proposition->insert;
    return {
        status      => $self->format_status($empire, $building->body),
        proposition => $proposition->get_status($empire),
    };
}

sub view_taxes_collected {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my @out;
    my $taxes = Lacuna->db->resultset('Lacuna::DB::Result::Taxes')->search({station_id => $building->body_id});
    while (my $tax = $taxes->next) {
        push @out, $tax->get_status();
    }
    return {
        status          => $self->format_status($empire, $building->body),
        taxes_collected    => \@out,
    };
}



__PACKAGE__->register_rpc_method_names(qw(get_bodies_for_star_in_jurisdiction get_mining_platforms_for_asteroid_in_jurisdiction propose_evict_mining_platform propose_members_only_mining_rights propose_members_only_colonization propose_rename_asteroid propose_rename_uninhabited propose_broadcast_on_network19 get_stars_in_jurisdiction propose_rename_star propose_repeal_law propose_transfer_station_ownership view_propositions view_laws cast_vote propose_fire_bfg propose_writ propose_elect_new_leader propose_induct_member propose_expel_member propose_taxation view_taxes_collected propose_foreign_aid propose_evict_excavator propose_members_only_excavation propose_neutralize_bhg));

no Moose;
__PACKAGE__->meta->make_immutable;

