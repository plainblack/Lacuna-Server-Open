package Lacuna::DB::Result::Alliance;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date randint);
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);
use DateTime;

__PACKAGE__->table('alliance');
__PACKAGE__->add_columns(
    name                    => { data_type => 'varchar', size => 30, is_nullable => 0 },
    leader_id               => { data_type => 'int', size => 11, is_nullable => 1 },
    forum_uri               => { data_type => 'varchar', size => 255, is_nullable => 0 },
    description             => { data_type => 'text', is_nullable => 1 },
    announcements           => { data_type => 'text', is_nullable => 1 },
    date_created            => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    stash                   => { data_type => 'mediumblob', is_nullable => 1, 'serializer_class' => 'JSON' },
    image                   => { data_type => 'varchar', size => 255, is_nullable => 0, default => 'default' },
); 

__PACKAGE__->belongs_to('leader', 'Lacuna::DB::Result::Empire', 'leader_id', { on_delete => 'set null' });
__PACKAGE__->has_many('members', 'Lacuna::DB::Result::Empire', 'alliance_id');
__PACKAGE__->has_many('invites', 'Lacuna::DB::Result::AllianceInvite', 'alliance_id');
__PACKAGE__->has_many('stations', 'Lacuna::DB::Result::Map::Body', 'alliance_id');
__PACKAGE__->has_many('laws', 'Lacuna::DB::Result::Law', 'alliance_id');
__PACKAGE__->has_many('propositions', 'Lacuna::DB::Result::Proposition', 'alliance_id');


sub date_created_formatted {
    my ($self) = @_;
    return format_date($self->date_created);
}

use constant max_stash => 500_000;

sub stash_size {
    my $self = shift;
    return $self->calculate_size_of_transaction($self->stash);
}

sub calculate_size_of_transaction {
    my ($self, $resources) = @_;
    my $size = 0;
    foreach my $resource (keys %{$resources}) {
        $size += $resources->{$resource};
    }
    return $size;
}

sub check_donation {
    my ($self, $body, $donation) = @_;
    my @valid = ('water','energy',FOOD_TYPES,ORE_TYPES);
    foreach my $resource (keys %{$donation}) {
        unless ($resource ~~ \@valid) {
            confess [1010, 'The stash cannot hold '.$resource.'.'];
        }
        $body->can_spend_type($resource, $donation->{$resource});
    }
    return 1;
}

sub add_to_stash {
    my ($self, $body, $donation) = @_;
    my $stash = $self->stash;
    foreach my $resource (keys %{$donation}) {
        $stash->{$resource} += $donation->{$resource};
        $body->spend_type($resource, $donation->{$resource});
    }
    $self->stash($stash);
}

sub donate {
    my ($self, $body, $donation) = @_;
    $self->check_donation($body, $donation);
    if ($self->max_stash - $self->stash_size < $self->calculate_size_of_transaction($donation)) {
        confess [1009, 'That would overflow the stash. The stash can only hold 500,000 resources.'];
    }
    $self->add_to_stash($body, $donation);
    $body->update;
    $self->update;
}

sub check_request {
    my ($self, $request, $max_exchange_size) = @_;
    my $stash = $self->stash;
    my $sum = 0;
    foreach my $resource (keys %{$request}) {
        if ($request->{$resource} > $stash->{$resource}) {
            confess [1010, 'The stash does not contain '.$request->{$resource}.' '.$resource.'.'];
        }
        $sum += $request->{$resource};
    }
    if ($sum > $max_exchange_size) {
        confess [1009, 'Your embassy level is too low to do a transaction that size. You can exchange '.$max_exchange_size.' per transaction.'];
    }
    return 1;
}

sub remove_from_stash {
    my ($self, $body, $request) = @_;
    my $stash = $self->stash;
    foreach my $resource (keys %{$request}) {
        $stash->{$resource} -= $request->{$resource};
        $body->add_type($resource, $request->{$resource});
    }
    $self->stash($stash);
}

sub exchange {
    my ($self, $body, $donation, $request, $max_exchange_size) = @_;
    $self->check_donation($body, $donation);
    if ($self->calculate_size_of_transaction($donation) != $self->calculate_size_of_transaction($request)) {
        confess [1009, 'The donation and request must be equal in size.'];
    }
    $self->check_request($request,$max_exchange_size);
    $self->add_to_stash($body, $donation);
    $self->remove_from_stash($body, $request);
    $body->update;
    $self->update;
}


sub get_status {
    my ($self, $private) = @_;

    my $members = $self->members;
    my @members_list;
    while (my $member = $members->next) {
        push @members_list, {
            id          => $member->id,
            name        => $member->name,
        };
    }
    my $stations = $self->stations;
    my @stations_list;
    my $influence = 0;
    while (my $station = $stations->next) {
        push @stations_list, {
            id          => $station->id,
            name        => $station->name,
            x           => $station->x,
            y           => $station->y,
        };
        $influence += $station->total_influence;
    }

    my $out = {
        id              => $self->id,
        name            => $self->name,
        description     => $self->description,
        date_created    => $self->date_created_formatted,
        leader_id       => $self->leader_id,
        members         => \@members_list,
        space_stations  => \@stations_list,
        influence       => $influence,
    };
    if ($private) {
        $out->{forum_uri} = $self->forum_uri;
        $out->{announcements} = $self->announcements;
    }
    return $out;
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


sub add_news {
    my ($self, $chance, $headline, $zone) = @_;

    $zone = "0|0" unless $zone;

    if (randint(1,100) <= $chance) {
        $headline = sprintf $headline, @_;
        Lacuna->db->resultset('News')->new({
            date_posted => DateTime->now,
            zone        => $zone,
            headline    => $headline,
        })->insert;
        return 1;
    }
    return 0;
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
    my $invite = Lacuna->db->resultset('AllianceInvite')->new({
        alliance_id => $self->id,
        empire_id   => $empire->id,
    })->insert;
    $empire->send_predefined_message(
        from        => $self->leader,
        tags        => ['Alliance','Correspondence'],
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
        tags        => ['Alliance','Correspondence'],
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
    # I has your probes!
    Lacuna->db->resultset('Probes')->search({empire_id => $empire->id})->update({alliance_id => $self->id});
    Lacuna->db->resultset('AllianceInvite')->search({empire_id => $empire->id})->delete;
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
    elsif ($empire->id == $self->leader_id) {
# Leader is probably self destructing, choose another leader.
        my $members = $self->members;
        my $last_log = DateTime->now->subtract( years => 5 );
        my $new_lead = $empire;
        while (my $member = $members->next) {
            if ($member->id != $self->leader_id and $member->last_login > $last_log) {
                $new_lead = $member;
                $last_log = $member->last_login;
            }
        }
        $self->leader_id($new_lead->id);
        $self->update;
#Send email to all alliance members notifying them of change in leadership.
    }

    my $stations = $self->stations;
    while (my $station = $stations->next) {
        if ($station->empire_id == $empire->id) {
            $station->empire_id($self->leader_id);
        }
        foreach my $chain ($station->in_supply_chains) {
            if ($chain->planet->empire_id == $empire->id) {
                $chain->delete;
            }
        }
        $station->update;
    }

    $empire->alliance_id(undef);
    $empire->update;
    Lacuna->db->resultset('Probes')->search({empire_id => $empire->id})->update({alliance_id => undef});
    return $self;
}

before delete => sub {
    my $self = shift;
    my $stations = $self->stations;
    while (my $station = $stations->next) {
        $station->sanitize;
    }
    my $members = $self->members;
    while (my $member = $members->next) {
        $self->remove_member($member, 1);
    }
};

sub send_predefined_message {
    my ($self, %options) = @_;
    my $members = $self->members;
    while (my $empire = $members->next) {
        $empire->send_predefined_message(%options);
    }
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
