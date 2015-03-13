package Lacuna::DB::Result::Propositions;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);
use DateTime;

__PACKAGE__->load_components('DynamicSubclass');
__PACKAGE__->table('propositions');
__PACKAGE__->add_columns(
    name                    => { data_type => 'varchar', size => 30, is_nullable => 0 },
    station_id              => { data_type => 'int', size => 11, is_nullable => 0 },
    votes_needed            => { data_type => 'int', is_nullable => 0, default_value => 1 },
    votes_yes               => { data_type => 'int', is_nullable => 0, default_value => 0 },
    votes_no                => { data_type => 'int', is_nullable => 0, default_value => 0 },
    description             => { data_type => 'text', is_nullable => 1 },
    type                    => { data_type => 'varchar', size => 30, is_nullable => 0 },
    scratch                 => { data_type => 'mediumblob', is_nullable => 1, 'serializer_class' => 'JSON' },
    date_ends               => { data_type => 'datetime', is_nullable => 0 },
    proposed_by_id          => { data_type => 'int', size => 11, is_nullable => 0 },
    status                  => { data_type => 'varchar', size => 10, is_nullable => 0, default_value => 'Pending' },
); 

__PACKAGE__->typecast_map(type => {
    AbandonStation          => 'Lacuna::DB::Result::Propositions::AbandonStation',
    BHGNeutralized          => 'Lacuna::DB::Result::Propositions::BHGNeutralized',
    BroadcastOnNetwork19    => 'Lacuna::DB::Result::Propositions::BroadcastOnNetwork19',
    DemolishModule          => 'Lacuna::DB::Result::Propositions::DemolishModule',
    DowngradeModule         => 'Lacuna::DB::Result::Propositions::DowngradeModule',
    EnactWrit               => 'Lacuna::DB::Result::Propositions::EnactWrit',
    ElectNewLeader          => 'Lacuna::DB::Result::Propositions::ElectNewLeader',
    EvictExcavator          => 'Lacuna::DB::Result::Propositions::EvictExcavator',
    EvictMiningPlatform     => 'Lacuna::DB::Result::Propositions::EvictMiningPlatform',
    ExpelMember             => 'Lacuna::DB::Result::Propositions::ExpelMember',
    FireBfg                 => 'Lacuna::DB::Result::Propositions::FireBfg',
    ForeignAid              => 'Lacuna::DB::Result::Propositions::ForeignAid',
    InductMember            => 'Lacuna::DB::Result::Propositions::InductMember',
    InstallModule           => 'Lacuna::DB::Result::Propositions::InstallModule',
    MembersOnlyColonization => 'Lacuna::DB::Result::Propositions::MembersOnlyColonization',
    MembersOnlyExcavation   => 'Lacuna::DB::Result::Propositions::MembersOnlyExcavation',
    MembersOnlyMiningRights => 'Lacuna::DB::Result::Propositions::MembersOnlyMiningRights',
    RenameAsteroid          => 'Lacuna::DB::Result::Propositions::RenameAsteroid',
    RenameStar              => 'Lacuna::DB::Result::Propositions::RenameStar',
    RenameStation           => 'Lacuna::DB::Result::Propositions::RenameStation',
    RenameUninhabited       => 'Lacuna::DB::Result::Propositions::RenameUninhabited',
    RepairModule            => 'Lacuna::DB::Result::Propositions::RepairModule',
    RepealLaw               => 'Lacuna::DB::Result::Propositions::RepealLaw',
    Taxation                => 'Lacuna::DB::Result::Propositions::Taxation',
    TransferStationOwnership=> 'Lacuna::DB::Result::Propositions::TransferStationOwnership',
    UpgradeModule           => 'Lacuna::DB::Result::Propositions::UpgradeModule',
});

__PACKAGE__->belongs_to('proposed_by', 'Lacuna::DB::Result::Empire', 'proposed_by_id');
__PACKAGE__->belongs_to('station', 'Lacuna::DB::Result::Map::Body', 'station_id');
__PACKAGE__->has_many('votes', 'Lacuna::DB::Result::Votes', 'proposition_id');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_status_date_ends', fields => ['status','date_ends']);
}

sub cast_vote {
    my ($self, $empire, $vote) = @_;
    unless ($self->status eq 'Pending') {
        confess [1009, 'This proposition has already '.$self->status.'.'];
    }
    if ($self->votes->search({empire_id => $empire->id})->count) {
        confess [1010, 'You have already voted on this proposition.'];
    }
    Lacuna->db->resultset('Lacuna::DB::Result::Votes')->new({
        proposition_id  => $self->id,
        empire_id       => $empire->id,
        vote            => $vote,
    })->insert;
    if ($vote) {
        $self->votes_yes( $self->votes_yes + 1 );
    }
    else {
        $self->votes_no( $self->votes_no + 1 );
    }
    $self->update;
    $self->check_status;
}

before delete => sub {
    my $self = shift;
    $self->fail if $self->status eq 'Pending';
    $self->votes->delete_all;
};

sub check_status {
    my $self = shift;
    if ($self->status eq 'Pending') {
        $self->votes_needed( int( ( $self->station->alliance->members->count + 1 ) / 2 ) );
    }
    if ($self->status ne 'Pending') {
    }
    elsif ($self->votes_yes >= $self->votes_needed) {
        $self->pass;
    }
    elsif ($self->votes_no >= $self->votes_needed) {
        $self->fail;        
    }
    elsif ($self->date_ends->epoch < time()) {
        $self->pass;
    }
    $self->update;
    return $self;
}

sub pass {
    my $self = shift;
    $self->station->alliance->send_predefined_message(
        filename    => 'parliament_vote_passed.txt',
        tags        => ['Parliament','Correspondence'],
        params      => [
            $self->name,
            $self->name,
            $self->votes_yes,
            $self->votes_no,
            $self->description,
            $self->pass_extra_message,
        ],
    );
    $self->status('Passed');
    return $self;
}

has pass_extra_message => (
    is  => 'rw',
);

sub fail {
    my $self = shift;
    $self->station->alliance->send_predefined_message(
        filename    => 'parliament_vote_failed.txt',
        tags        => ['Parliament','Correspondence'],
        params      => [
            $self->name,
            $self->name,
            $self->votes_yes,
            $self->votes_no,
            $self->description,
            $self->fail_extra_message,
        ],
    );
    $self->status('Failed');
    return $self;
}

has fail_extra_message  => (
    is  => 'ro',
);

before insert => sub {
    my $self = shift;
    $self->votes_needed( int( ( $self->station->alliance->members->count + 1 ) / 2 ) );
    $self->date_ends( DateTime->now->add(hours => 72) );
};

after insert => sub {
    my $self = shift;
    $self->send_vote;
};

sub get_status {
    my ($self, $empire) = @_;
    my $out = {
        id          => $self->id,
        name        => $self->name,
        description => $self->description,
        votes_needed=> $self->votes_needed,
        votes_yes   => $self->votes_yes,
        votes_no    => $self->votes_no,
        status      => $self->status,
        date_ends   => $self->date_ends_formatted,
        station     => $self->station->name,
        proposed_by => {
            id      => $self->proposed_by->id,
            name    => $self->proposed_by->name,
        },
    };
    if (defined $empire) {
        my $vote = $self->votes->search({ empire_id => $empire->id})->first;
        if (defined $vote) {
            $out->{my_vote} = $vote->vote;
        }
    }
    return $out;
}

sub send_vote {
    my $self = shift;
    my $station = $self->station;
    my $parliament = $station->parliament;
    $station->alliance->send_predefined_message(
        filename    => 'parliament_vote.txt',
        tags        => ['Parliament','Correspondence'],
        from        => $self->proposed_by,
        params      => [
            $self->name,
            $self->name,
            $self->description,
            $station->id,
            $parliament->id,
            $self->id,
            $station->id,
            $parliament->id,
            $self->id,
        ],
    );
}

sub date_ends_formatted {
    my ($self) = @_;
    return format_date($self->date_ends);
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
