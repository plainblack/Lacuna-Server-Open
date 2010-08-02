package Lacuna::RPC::Building::Embassy;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/embassy';
}

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
    my $new_leader = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($empire_id);
    unless (defined $new_leader) {
        confess [1002, 'The empire you specified to take over as leader does not exist.'];
    }
    $building->assign_alliance_leader($new_leader);
    return {
        status          => $self->format_status($empire, $building->body),
        alliance        => $building->alliance,
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
    my $member = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($member_id);
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
    my $invite = Lacuna->db->resultset('Lacuna::DB::Result::AllianceInvite')->find($invite_id);
    unless (defined $invite) {
        confess [1002, 'Invitation not found.'];
    }
    $building->accept_invite($invite, $message);
    return $self->get_alliance_status($empire, $building);
}

sub reject_invite {
    my ($self, $session_id, $building_id, $invite_id, $message) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    unless ($invite_id) {
        confess [1002, 'You must specify an invite id.'];
    }
    my $invite = Lacuna->db->resultset('Lacuna::DB::Result::AllianceInvite')->find($invite_id);
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
    my $invite = Lacuna->db->resultset('Lacuna::DB::Result::AllianceInvite')->find($invite_id);
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
    my $invitee = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($empire_id);
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


__PACKAGE__->register_rpc_method_names(qw(expel_member update_alliance get_pending_invites get_my_invites assign_alliance_leader create_alliance dissolve_alliance send_invite accept_invite withdraw_invite reject_invite leave_alliance get_alliance_status));


no Moose;
__PACKAGE__->meta->make_immutable;

