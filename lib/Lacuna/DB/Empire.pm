package Lacuna::DB::Empire;

use Moose;
extends 'SimpleDB::Class::Item';
use DateTime;
use Lacuna::Util qw(format_date);
use Digest::SHA;
use Lacuna::Constants qw(MEDALS);
use List::MoreUtils qw(uniq);

__PACKAGE__->set_domain_name('empire');
__PACKAGE__->add_attributes(
    name            => { isa => 'Str', 
        trigger => sub {
            my ($self, $new, $old) = @_;
            $self->name_cname(Lacuna::Util::cname($new));
        },
    },
    stage               => { isa => 'Str', default=>'new'},
    name_cname          => { isa => 'Str' },
    date_created        => { isa => 'DateTime' },
    description         => { isa => 'Str' },
    home_planet_id      => { isa => 'Str' },
    status_message      => { isa => 'Str' },
    friends_and_foes    => { isa => 'Str' },
    password            => { isa => 'Str' },
    last_login          => { isa => 'DateTime' },
    species_id          => { isa => 'Str' },
    essentia            => { isa => 'Int', default=>0 },
    points              => { isa => 'Int', default=>0 },
    rank                => { isa => 'Int', default=>0 }, # just where it is stored, but will come out of date quickly
    probed_stars        => { isa => 'ArrayRefOfStr' },
    university_level    => { isa => 'Int', default=>0 },
    medals              => { isa => 'HashRef' },
    needs_full_update   => { isa => 'Str', default=>0 },
);

# personal confederacies

__PACKAGE__->belongs_to('species', 'Lacuna::DB::Species', 'species_id');
__PACKAGE__->belongs_to('home_planet', 'Lacuna::DB::Body::Planet', 'home_planet_id', mate=>'empire');
__PACKAGE__->has_many('sessions', 'Lacuna::DB::Session', 'empire_id', mate => 'empire');
__PACKAGE__->has_many('planets', 'Lacuna::DB::Body::Planet', 'empire_id', mate => 'empire');
__PACKAGE__->has_many('sent_messages', 'Lacuna::DB::Message', 'from_id', mate => 'sender');
__PACKAGE__->has_many('received_messages', 'Lacuna::DB::Message', 'to_id', mate => 'receiver');
__PACKAGE__->has_many('build_queues', 'Lacuna::DB::BuildQueue', 'empire_id', mate => 'empire');


sub get_body { # makes for uniform error handling, and prevents staleness
    my ($self, $body_id) = @_;
    my $body = $self->simpledb->domain('body')->find($body_id);
    unless (defined $body) {
        confess [1002, 'Body does not exist.', $body_id];
    }
    unless ($body->empire_id eq $self->id) {
        confess [1010, "Can't manipulate a planet you don't inhabit."];
    }
    $body->empire($self);
    if (!$self->has_home_planet && $body->id eq $self->home_planet_id) {
        $self->home_planet($body);
    }
    return $body;
}

sub get_building { # makes for uniform error handling, and prevents staleness
    my ($self, $moniker, $building_id) = @_;
    if (ref $building_id && $building_id->isa('Lacuna::DB::Building')) {
        return $building_id;
    }
    else {
        my $building = $self->simpledb->domain($moniker)->find($building_id);
        unless (defined $building) {
            confess [1002, 'Building does not exist.', $building_id];
        }
        my $body = $self->get_body($building->body_id);        
        unless ($body->empire_id eq $self->id) { # do body, because permanents aren't owned by anybody
            confess [1010, "Can't manipulate a building that you don't own.", $building_id];
        }
        $building->empire($self);
        $building->body($body);
        return $building;
    }
}

sub add_medal {
    my ($self, $id, %options) = @_;
    my $medals = $self->medals;
    unless (exists $medals->{$id}) {
        $medals->{$id} = {
            date    => format_date(DateTime->now),
            note    => $options{notes},
            public  => 1,
            };
        $self->medals($medals);
        $self->put unless $options{skip_put};
        my $name = MEDALS->{$id};
        $self->send_message(
            tags    => ['Medal'],
            subject => $name,
            body    => sprintf('You were just awarded a "%s" medal.', $name),
            );
    }
    return $self;
}

sub spend_essentia {
    my ($self, $value) = @_;
    $self->essentia( $self->essentia - $value );
    return $self;
}

sub add_essentia {
    my ($self, $value) = @_;
    $self->essentia( $self->essentia + $value );
    return $self;
}

sub get_new_message_count {
    my $self = shift;
    return $self->simpledb->domain('message')->count(where => { to_id=>$self->id, has_archived => ['!=', 1], has_read => ['!=', 1]});
}

sub get_status {
    my ($self) = @_;
    my $status = {
        server  => {
            'time'  => format_date(DateTime->now),
            version => Lacuna->version,
        },
        empire  => {
            full_status_update_required => $self->needs_full_update,
            has_new_messages            => $self->get_new_message_count,
        },
    };
    return $status;
}

sub get_full_status {
    my ($self) = @_;
    my $planet_rs = $self->planets;
    my %planets;
    my $happiness = 0;
    my $happiness_hour = 0;
    while (my $planet = $planet_rs->next) {
        $planet->tick;
        $planets{$planet->id} = $planet->get_status($self);
        $happiness += $planet->happiness;
        $happiness_hour += $planet->happiness_hour;
    }
    my $status = {
        server  => {
            'time'          => format_date(DateTime->now),
            version         => Lacuna->version,
            star_map_size   => Lacuna->config->get('map_size'),
        },
        empire  => {
            status_message      => $self->status_message,
            happiness           => $happiness,
            happiness_hour      => $happiness_hour,
            name                => $self->name,
            id                  => $self->id,
            essentia            => $self->essentia,
            has_new_messages    => $self->get_new_message_count,
            home_planet_id      => $self->home_planet_id,
            planets             => \%planets,
        },
    };
    $self->needs_full_update(0);
    $self->put;
    return $status;
}

sub start_session {
    my $self = shift;
    my $session = $self->simpledb->domain('session')->insert({
        empire_id       => $self->id,
        date_created    => DateTime->now,
        expires         => DateTime->now->add(hours=>2), 
    });
    $self->last_login(DateTime->now);
    $self->put;
    return $session;
}

sub is_password_valid {
    my ($self, $password) = @_;
    return ($self->password eq $self->encrypt_password($password)) ? 1 : 0;
}
sub encrypt_password {
    my ($self, $password) = @_;
    return Digest::SHA::sha256_base64($password);
}

sub create {
    my ($class, $simpledb, $account, $empire_id) = @_;
    my %options;
    if ($empire_id) {
        $options{id} = $empire_id;
    }
    return $simpledb->domain('empire')->insert({
        name                => $account->{name},
        date_created        => DateTime->now,
        species_id          => 'human_species',
        status_message      => 'Making Lacuna a better Expanse.',
        password            => $class->encrypt_password($account->{password}),
    }, %options);
}

sub found {
    my ($self, $home_planet) = @_;

    # found empire
    unless ($home_planet) {
        $home_planet = $self->species->find_home_planet;
    }
    $home_planet->empire($self);
    $self->home_planet($home_planet);
    $self->home_planet_id($home_planet->id);
    $self->probed_stars([$home_planet->star_id]);
    $self->add_essentia(100); # REMOVE BEFORE LAUNCH
    $self->stage('founded');
    $self->put;

    # send welcome
    $self->send_predefined_message(
        filename    => 'welcome.txt',
        from        => $self->lacuna_expanse_corp,
        params      => [$self->name],
        tags        => ['Tutorial','Correspondence'],
    );
    
    # found colony
    $home_planet->found_colony($self);
    
    $self = $home_planet->empire; # we're stale
    
    return $self;
}

sub send_message {
    my ($self, %params) = @_;
    $params{simpledb} = $self->simpledb;
    $params{from}   = $params{from} || $self;
    $params{to}     = $self;
    Lacuna::DB::Message->send(%params);
}

sub send_predefined_message {
    my ($self, %options) = @_;
    my $path = '/data/Lacuna-Server/var/messages/'.$options{filename};
    if (open my $file, "<", $path) {
        my $subject = <$file>;
        chomp $subject;
        my $message;
        {
            local $/;
            $message = <$file>;
        }
        close $file;
        return $self->send_message(
            subject => $subject,
            body    => sprintf($message, @{$options{params}}),
            from    => $options{from},
            tags    => $options{tags},
            );
    }
    else {
        warn "Couldn't send message using $path";
    }
}

sub lacuna_expanse_corp {
    my $self = shift;
    return $self->simpledb->domain('empire')->find('lacuna_expanse_corp');
}

sub add_probe {
    my ($self, $star_id) = @_;
    my @probes = @{$self->probed_stars};
    push @probes, $star_id;
    my @unique = uniq @probes;
    $self->probed_stars(\@unique);
    return $self;
}

before 'delete' => sub {
    my ($self) = @_;
    my $db = $self->simpledb;
    $self->sent_messages->delete;
    $self->received_messages->delete;
    $self->build_queues->delete;
    my $planets = $self->planets;
    while ( my $planet = $planets->next ) {
        $planet->sanitize;
    }
    if ($self->species_id ne 'human_species') {
        $self->species->delete if defined $self->species;
    }
    $self->sessions->delete;
};

sub trigger_full_update {
    my ($self, %options) = @_;
    if ($self->needs_full_update) {
        $self->needs_full_update(1);
        $self->put unless $options{skip_put};
    }
    return $self;
}

no Moose;
__PACKAGE__->meta->make_immutable;
