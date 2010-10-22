package Lacuna::DB::Result::Alliance;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);
use DateTime;

__PACKAGE__->table('alliance');
__PACKAGE__->add_columns(
    name                    => { data_type => 'varchar', size => 30, is_nullable => 0 },
    leader_id               => { data_type => 'int', size => 11, is_nullable => 1 },
    forum_uri               => { data_type => 'varchar', size => 255, is_nullable => 0 },
    description             => { data_type => 'text', is_nullable => 1 },
    announcements           => { data_type => 'text', is_nullable => 1 },
    date_created            => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
);

__PACKAGE__->belongs_to('leader', 'Lacuna::DB::Result::Empire', 'leader_id', { on_delete => 'set null' });
__PACKAGE__->has_many('members', 'Lacuna::DB::Result::Empire', 'alliance_id');
__PACKAGE__->has_many('invites', 'Lacuna::DB::Result::AllianceInvite', 'alliance_id');


sub date_created_formatted {
    my ($self) = @_;
    return format_date($self->date_created);
}

sub get_status {
    my $self = shift;
    my $members = $self->members;
    my @members_list;
    while (my $member = $members->next) {
        push @members_list, {
            empire_id   => $member->id,
            name        => $member->name,
        };
    }
    return {
        id              => $self->id,
        members         => \@members_list,
        leader_id       => $self->leader_id,
        forum_uri       => $self->forum_uri,
        description     => $self->description,
        name            => $self->name,
        announcements   => $self->announcements,
        date_created    => $self->date_created_formatted,
    };
}

sub get_invites {
    my $self = shift;
    my $invites = $self->invites;
    my @out;
    while (my $invite = $invites->next) {
        my $empire = $invite->empire;
        push @out, {
            id          => $invite->id,
            name        => $empire->name,
            empire_id   => $empire->id,
        };
    }
    return \@out;
}


sub send_invite {
    my ($self, $empire, $message) = @_;
    Lacuna::Verify->new(content=>\$message, throws=>[1005,'Message must not contain restricted characters or profanity.', 'message'])
        ->no_tags
        ->no_profanity;
    if (! defined $empire ) {
        confess [1002, 'No empire specified.'];
    }
    elsif ($empire->alliance_id == $self->id) {
        confess [1010, 'Already a member of this alliance.']
    }
    my $invite = Lacuna->db->resultset('Lacuna::DB::Result::AllianceInvite')->new({
        alliance_id => $self->id,
        empire_id   => $empire->id,
    })->insert;
    $empire->send_predefined_message(
        from        => $self->leader,
        tags        => ['Correspondence'],
        filename    => 'alliance_invite.txt',
        params      => [$self->id, $self->name, $message],
    );
    return $invite;
}

sub withdraw_invite {
    my ($self, $invite, $message) = @_;
    Lacuna::Verify->new(content=>\$message, throws=>[1005,'Message must not contain restricted characters or profanity.', 'message'])
        ->no_tags
        ->no_profanity;
    if (! defined $invite ) {
        confess [1002, 'No invite specified.'];
    }
    my $empire = $invite->empire;
    $invite->delete;
    $empire->send_predefined_message(
        from        => $self->leader,
        tags        => ['Correspondence'],
        filename    => 'alliance_withdraw_invite.txt',
        params      => [$self->id, $self->name, $message],
    );
}

sub add_member {
    my ($self, $empire) = @_;
    if (! defined $empire ) {
        confess [1002, 'No empire specified.'];
    }
    elsif ($empire->alliance_id && $empire->alliance_id != $self->id) {
        confess [1010, 'Already a member of another alliance.']
    }
    elsif ($empire->alliance_id == $self->id) {
        confess [1010, 'Already a member of this alliance.']
    }
    $empire->alliance_id($self->id);
    $empire->update;
    Lacuna->db->resultset('Lacuna::DB::Result::Probes')->search({empire_id => $empire->id})->update({alliance_id => $self->id});
    Lacuna->db->resultset('Lacuna::DB::Result::AllianceInvite')->search({empire_id => $empire->id})->delete;
    return $self;
}

sub remove_member {
    my ($self, $empire, $delete_leader) = @_;
    if (! defined $empire ) {
        confess [1002, 'No empire specified.'];
    }
    elsif ($empire->alliance_id != $self->id) {
        confess [1010, 'Not a member of this alliance.'];
    }
    elsif ($empire->id == $self->leader_id && !$delete_leader) {
        confess [1010, 'The leader of the alliance cannot be removed from the alliance.'];
    }
    $empire->alliance_id(undef);
    $empire->update;
    Lacuna->db->resultset('Lacuna::DB::Result::Probes')->search({empire_id => $empire->id})->update({alliance_id => undef});
    return $self;
}

before delete => sub {
    my $self = shift;
    my $members = $self->members;
    while (my $member = $members->next) {
        $self->remove_member($member, 1);
    }
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
