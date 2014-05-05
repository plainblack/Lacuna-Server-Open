package Lacuna::DB::Result::Law;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);
use DateTime;

__PACKAGE__->load_components('DynamicSubclass');
__PACKAGE__->table('law');
__PACKAGE__->add_columns(
    name                    => { data_type => 'varchar', size => 30, is_nullable => 0 },
    description             => { data_type => 'text', is_nullable => 1 },
    type                    => { data_type => 'varchar', size => 30, is_nullable => 0 },
    date_enacted            => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    alliance_id             => { data_type => 'int', size => 11, is_nullable => 1 },
    star_id                 => { data_type => 'int', is_nullable => 1 },
    zone                    => { data_type => 'varchar', size => 16, is_nullable => 1 },
    scratch                 => { data_type => 'mediumblob', is_nullable => 1, 'serializer_class' => 'JSON' },
); 

__PACKAGE__->typecast_map(type => {
    BHGNeutralized          => 'Lacuna::DB::Result::Law::BHGNeutralized',
    Jurisdiction            => 'Lacuna::DB::Result::Law::Jurisdiction',
    MembersOnlyColonization => 'Lacuna::DB::Result::Law::MembersOnlyColonization',
    MembersOnlyMiningRights => 'Lacuna::DB::Result::Law::MembersOnlyMiningRights',
    Taxation                => 'Lacuna::DB::Result::Law::Taxation',
    Writ                    => 'Lacuna::DB::Result::Law::Writ',
});

__PACKAGE__->belongs_to('star', 'Lacuna::DB::Result::Map::Star', 'star_id', { on_delete => 'set null' });
__PACKAGE__->belongs_to('alliance', 'Lacuna::DB::Result::Alliance', 'alliance_id');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_date_enacted', fields => ['date_enacted']);
}

before delete => sub {
    my $self = shift;
    $self->notify_about_law('parliament_law_repealed.txt');
};

after insert => sub {
    my $self = shift;
    $self->notify_about_law('parliament_law_enacted.txt');
};

sub notify_about_law {
    my ($self, $filename) = @_;
    if ($self->star_id) {
        $self->notify_stellar_inhabitants($self->star, $filename);
    }
    elsif ($self->zone) {
        $self->notify_zone_inhabitants($self->zone, $filename);
    }
    else {
        # Perhaps notify alliance members?
    }
}

sub notify_stellar_inhabitants {
    my ($self, $star, $filename) = @_;

    # Inhabited planets around the star
    my $planets = $star->bodies->search({empire_id => {'!=' => undef } });
    my $alliance = $self->alliance;
    my $from = $alliance->leader;
    while (my $planet = $planets->next) {
        $planet->empire->send_predefined_message(
            filename    => $filename,
            from        => $from,
            params      => [$self->name, $alliance->name, $planet->name, $self->description],
            tags        => ['Parliament','Correspondence'],
        );
    }
}

sub notify_zone_inhabitants {
    my ($self, $zone, $filename) = @_;

    my $stars = Lacuna->db->resultset('Map::Star')->search({
        zone        => $zone,
        alliance_id => $self->alliance_id,
        seize_strength => {'>' => 50},
    });
    while (my $star = $stars->next) {
        $self->notify_stellar_inhabitants($star, $filename);
    }
}


sub get_status {
    my ($self) = @_;
    my $out = {
        id          => $self->id,
        name        => $self->name,
        description => $self->description,
        date_enacted   => $self->date_enacted_formatted,
    };
    return $out;
}

sub date_enacted_formatted {
    my ($self) = @_;
    return format_date($self->date_enacted);
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
