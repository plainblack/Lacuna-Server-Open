package Lacuna::DB::Result::Building::Embassy;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
use Lacuna::Util qw(format_date);
use List::Util qw(max);

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure));
};

use constant controller_class => 'Lacuna::RPC::Building::Embassy';

use constant max_instances_per_planet => 1;

use constant university_prereq => 5;

use constant image => 'embassy';

use constant name => 'Embassy';

use constant food_to_build => 65;

use constant energy_to_build => 65;

use constant ore_to_build => 65;

use constant water_to_build => 65;

use constant waste_to_build => 70;

use constant time_to_build => 150;

use constant food_consumption => 6;

use constant energy_consumption => 6;

use constant ore_consumption => 1;

use constant water_consumption => 6;

use constant waste_production => 1;

# by accepting an optional level, we can centralise the calculation.
# default level, of course, is the embassy's effective level (based on uni level, etc).
sub max_members {
    my $self  = shift;
    my $level = @_ ? shift : $self->effective_level;
    return $level * 2;
}

sub alliance {
    my $self = shift;
    my $empire = $self->body->empire;
    unless ($empire->alliance_id) {
        confess [1002, 'You are not part of any alliance.'];
    }
    return $empire->alliance;
}

sub create_alliance {
    my ($self, $name) = @_;
    my $body = $self->body;
    my $empire = $body->empire;
    if ($empire->alliance_id) {
        confess [1010, 'Cannot form a new alliance, while you belong to an existing alliance.'];
    }
    my $alliances = Lacuna->db->resultset('Lacuna::DB::Result::Alliance');
    Lacuna::Verify->new(content=>\$name, throws=>[1000,'Alliance name not available.', 'name'])
        ->length_lt(31)
        ->length_gt(2)
        ->not_empty
        ->no_padding
        ->no_restricted_chars
        ->no_profanity
        ->ok( !$alliances->search({name=>$name})->count );
    my $alliance = $alliances->new({
        name        => $name,
        leader_id   => $empire->id,
    });
    $alliance->insert;
    $alliance->add_member($empire);
    $body->add_news(60,sprintf('A pact was formed by unnamed parties today, which formed a shadowy organization known only as %s.', $alliance->name));
    return $alliance;
}

sub get_alliance_status {
    my $self = shift;
    return $self->alliance->get_status;
}

sub accept_invite {
    my ($self, $invite, $message) = @_;
    Lacuna::Verify->new(content=>\$message, throws=>[1005,'Message must not contain restricted characters or profanity.', 'message'])
        ->no_tags
        ->no_profanity;
    if ($invite->empire_id ne $self->body->empire_id) {
        confess [1010, 'You cannot accept an invite that is not yours.'];
    }
    my $empire = $self->body->empire;
    if ($empire->alliance_id) {
        confess [1010, 'You are already a member of an alliance. Leave that one before joining another.'];
    }
    my $alliance = $invite->alliance;
    $alliance->add_member($empire);
    $invite->alliance->leader->send_predefined_message(
        from        => $empire,
        tags        => ['Alliance','Correspondence'],
        filename    => 'alliance_accept.txt',
        params      => [$message, $empire->name],
    );
}

sub reject_invite {
    my ($self, $invite, $message) = @_;
    Lacuna::Verify->new(content=>\$message, throws=>[1005,'Message must not contain restricted characters or profanity.', 'message'])
        ->no_tags
        ->no_profanity;
    if ($invite->empire_id ne $self->body->empire_id) {
        confess [1010, 'That invite is not yours to reject.'];
    }
    my $empire = $self->body->empire;
    $invite->alliance->leader->send_predefined_message(
        from        => $empire,
        tags        => ['Alliance','Correspondence'],
        filename    => 'alliance_reject.txt',
        params      => [$message, $empire->name],
    );
    $invite->delete;
}

sub leave_alliance {
    my ($self, $message) = @_;
    Lacuna::Verify->new(content=>\$message, throws=>[1005,'Message must not contain restricted characters or profanity.', 'message'])
        ->no_tags
        ->no_profanity;
    my $empire = $self->body->empire;
    unless ($empire->alliance_id) {
        confess [1010, 'You cannot leave an alliance you are not part of.'];
    }
    my $alliance = $empire->alliance;
    $alliance->remove_member($empire);
    $alliance->leader->send_predefined_message(
        from        => $empire,
        tags        => ['Alliance','Correspondence'],
        filename    => 'alliance_leave.txt',
        params      => [$message, $empire->name],
    );
}

sub expel_member {
    my ($self, $empire_to_remove, $message) = @_;
    Lacuna::Verify->new(content=>\$message, throws=>[1005,'Message must not contain restricted characters or profanity.', 'message'])
        ->no_tags
        ->no_profanity;
    my $alliance = $self->alliance;
    if ($self->body->empire_id != $alliance->leader_id) {
        confess [1010, 'Only the alliance leader can expel a member.'];
    }
    $alliance->remove_member($empire_to_remove);
    $empire_to_remove->send_predefined_message(
        from        => $alliance->leader,
        tags        => ['Alliance','Correspondence'],
        filename    => 'alliance_expelled.txt',
        params      => [$alliance->id, $alliance->name, $message, $alliance->name],
    );
}

sub send_invite {
    my ($self, $empire, $message) = @_;
    my $alliance = $self->alliance;
    my $count = $alliance->members->count;
    $count += $alliance->invites->count;
    if ($count >= $self->max_members ) {
        confess [1009, 'You may only have '.$self->max_members.' in or invited to this alliance.'];
    }
    $alliance->send_invite($empire, $message);
}

sub withdraw_invite {
    my ($self, $invite, $message) = @_;
    $self->alliance->withdraw_invite($invite, $message);
}

sub dissolve_alliance {
    my ($self) = @_;
    my $alliance = $self->alliance;
    my $body = $self->body;
    if ($body->empire_id != $alliance->leader_id) {
        confess [1010, 'Only the alliance leader can dissolve an alliance.'];
    }
    $body->add_news(60,sprintf('The organization known as %s dissolved today amid rumors of scandal.', $alliance->name));
    $alliance->delete;
}

sub assign_alliance_leader {
    my ($self, $empire) = @_;
    my $alliance = $self->alliance;
    if ($self->body->empire_id != $alliance->leader_id) {
        confess [1010, 'Only the alliance leader can set another alliance leader.'];
    }
    if ($empire->alliance_id != $alliance->id) {
        confess [1010, 'Cannot set a non-member to lead an alliance.'];
    }
    $alliance->leader_id($empire->id);
    $alliance->update;
}

sub get_pending_invites {
    my $self = shift;
    my $alliance = $self->alliance;
    if ($self->body->empire_id != $alliance->leader_id) {
        confess [1010, 'Only the alliance leader can view pending invites.'];
    }
    return $alliance->get_invites;
}

sub get_my_invites {
    my $self = shift;
    my $invites = Lacuna->db->resultset('Lacuna::DB::Result::AllianceInvite')->search({empire_id => $self->body->empire_id});
    my @out;
    while (my $invite = $invites->next) {
        my $alliance = $invite->alliance;
        push @out, {
            id              => $invite->id,
            name            => $alliance->name,
            alliance_id     => $alliance->id,
        };
    }
    return \@out;
}

sub update_alliance {
    my ($self, $params) = @_;
    my $alliance = $self->alliance;
    if ($self->body->empire_id != $alliance->leader_id) {
        confess [1010, 'Only the alliance leader can update the alliance information.'];
    }
    my %vetted;
    foreach my $field (qw(forum_uri description announcements)) {
        next unless exists $params->{$field};
        my $content = $params->{$field};
        Lacuna::Verify->new(content=>\$content, throws=>[1005,'The '.$field.' must not contain restricted characters or profanity.', $field])
            ->no_tags
            ->no_profanity;
        $vetted{$field} = $content;
    }
    $alliance->update(\%vetted);
    return $alliance;
}

sub exchange_with_stash {
    my ($self, $donation, $request) = @_;
    unless ($self->exchanges_remaining_today) {
        confess [1009, 'You have already reached your stash exchange limit for the day at this embassy.']
    }
    $self->alliance->exchange($self->body, $donation, $request, $self->max_exchange_size);
    Lacuna->cache->increment('stash_exchanges_'.format_date(undef,'%d'), $self->body_id, 1, 60 * 60 * 26);
    $self->exchanges_remaining_today( $self->exchanges_remaining_today - 1 );
}

sub max_exchange_size {
    my $self = shift;
    return $self->effective_level * 10000; 
}

has exchanges_remaining_today => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->effective_level - Lacuna->cache->get('stash_exchanges_'.format_date(undef,'%d'), $self->body_id);
    },
);


before 'can_downgrade' => sub {
    my $self = shift;
    my $alliance = eval{$self->alliance};
    if (defined $alliance && $self->body->empire_id == $alliance->leader_id) {
        my $alliance_members = $alliance->members->count;
        my $best_other_embassy = $self->body->empire
            ->highest_embassy($self->body_id);
        my $allowed_members  = max(
            defined $best_other_embassy ? $best_other_embassy->max_members : 0,
            $self->max_members($self->level - 1)
        );
        if ($alliance_members > $allowed_members) {
            confess [1013, 'You cannot downgrade this Embassy while you are an alliance leader with ' . $alliance_members . ' members.']
        }
    }
};

before 'can_demolish' => sub {
    my $self = shift;
    my $alliance = eval{$self->alliance};
    if (defined $alliance && $self->body->empire_id == $alliance->leader_id) {
        # as alliance leader, can only demolish if there's another
        # embassy able to take over.
        my $alliance_members = $alliance->members->count;
        my $best_other_embassy = $self->body->empire
            ->highest_embassy($self->body_id);
        my $allowed_members  = defined $best_other_embassy ? $best_other_embassy->max_members : 0;
        if ($alliance_members > $allowed_members) {
            confess [1013, 'You cannot demolish this Embassy while you are an alliance leader.  Reassign leadership or dissolve the alliance first.']
        }
    }
};

# all propositions from all stations for this alliance visible in the embassy.
sub propositions {
    my ($self) = @_;
    my $alliance = $self->alliance;
    return Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->
        search({ "station.alliance_id" => $alliance->id, }, { prefetch => "station" });
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
