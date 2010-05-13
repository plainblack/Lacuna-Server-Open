package Lacuna::DB::Result::Empire;

use Moose;
extends 'Lacuna::DB::Result';
use DateTime;
use Lacuna::Util qw(format_date);
use Digest::SHA;
use List::MoreUtils qw(uniq);

__PACKAGE__->table('empire');
__PACKAGE__->add_columns(
    name                    => { data_type => 'char', size => 30, is_nullable => 0 },
    stage                   => { data_type => 'char', size => 30, is_nullable => 0, default_value => 'new' },
    date_created            => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    description             => { data_type => 'text', is_nullable => 1 },
    home_planet_id          => { data_type => 'int', size => 11, is_nullable => 1 },
    status_message          => { data_type => 'char', size => 255 },
    password                => { data_type => 'char', size => 255 },
    last_login              => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    species_id              => { data_type => 'int', size => 11, is_nullable => 0 },
    essentia                => { data_type => 'int', size => 11, default_value => 0 },
#    points                  => { data_type => 'int', size => 11, default_value => 0 },
#    rank                   => { data_type => 'int', size => 11, default_value => 0 }, # just where it is stored, but will come out of date quickly
    university_level        => { data_type => 'int', size => 3, default_value => 0 },
    needs_full_update       => { data_type => 'int', size => 1, default_value => 0 },
    tutorial_stage          => { data_type => 'char', size => 30, is_nullable => 0, default_value => 'explore_the_ui' },
    tutorial_scratch        => { data_type => 'text', is_nullable => 1 },
    is_isolationist         => { data_type => 'int', size => 1, default_value => 1 },
    food_boost              => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    water_boost             => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    ore_boost               => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    energy_boost            => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    happiness_boost         => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
);

# personal confederacies

__PACKAGE__->belongs_to('species', 'Lacuna::DB::Result::Species', 'species_id');
__PACKAGE__->belongs_to('home_planet', 'Lacuna::DB::Result::Body', 'home_planet_id');
__PACKAGE__->has_many('sessions', 'Lacuna::DB::Result::Session', 'empire_id');
__PACKAGE__->has_many('planets', 'Lacuna::DB::Result::Body', 'empire_id');
__PACKAGE__->has_many('sent_messages', 'Lacuna::DB::Result::Message', 'from_id');
__PACKAGE__->has_many('received_messages', 'Lacuna::DB::Result::Message', 'to_id');
__PACKAGE__->has_many('medals', 'Lacuna::DB::Result::Medals', 'empire_id');
__PACKAGE__->has_many('probes', 'Lacuna::DB::Result::Probes', 'empire_id');

sub get_body { # makes for uniform error handling, and prevents staleness
    my ($self, $body_id) = @_;
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Body')->find($body_id);
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
    if (ref $building_id && $building_id->isa('Lacuna::DB::Result::Building')) {
        return $building_id;
    }
    else {
        my $building = Lacuna->db->resultset($moniker)->find($building_id);
        unless (defined $building) {
            confess [1002, 'Building does not exist.', $building_id];
        }
        $building->is_offline;
        my $body = $self->get_body($building->body_id);        
        unless ($body->empire_id eq $self->id) { 
            confess [1010, "Can't manipulate a building that you don't own.", $building_id];
        }
        $body->tick;
        $building->get_from_storage; # in case it changed due to the tick
        $building->body($body);
        return $building;
    }
}

sub has_medal {
    my ($self, $type) = @_;
    return Lacuna->db->resultset('Lacuna::DB::Result::Medals')->search({empire_id => $self->id, type => $type})->count;
}

sub add_medal {
    my ($self, $type) = @_;
    unless ($self->has_medal($type)) {
        my $medal = Lacuna->db->resultset('Lacuna::DB::Result::Medals')->new({
            datestamp   => DateTime->now,
            public      => 1,
            empire_id   => $self->id,
            type        => $type,
        })->insert;
        my $name = $medal->name;
        $self->send_predefined_message(
            tags        => ['Medal'],
            filename    => 'medal.txt',
            params      => [$name, $name, $self->name],
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
    return Lacuna->db->resultset('Lacuna::DB:Result::Message')->search({
        to_id           => $self->id,
        has_archived    => {'!=' => 1},
        has_read        => {'!=' => 1}
    })->count;
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
    my @planet_ids;
    while (my $planet = $planet_rs->next) {
        $planets{$planet->id} = $planet->get_status($self);
        $happiness += $planet->happiness;
        $happiness_hour += $planet->happiness_hour;
        push @planet_ids, $planet->id;
    }
    $self->body_ids(\@planet_ids);
    my $status = {
        server  => {
            'time'          => format_date(DateTime->now),
            version         => Lacuna->version,
            star_map_size   => Lacuna->config->get('map_size'),
        },
        empire  => {
            is_isolationist     => $self->is_isolationist,
            status_message      => $self->status_message,
            happiness           => $happiness,
            happiness_hour      => $happiness_hour,
            name                => $self->name,
            id                  => $self->id,
            essentia            => $self->essentia,
            has_new_messages    => $self->get_new_message_count,
            home_planet_id      => $self->home_planet_id,
            planets             => \%planets,
            next_planet_cost    => $self->next_planet_cost,
        },
    };
    $self->needs_full_update(0);
    $self->update;
    return $status;
}

sub start_session {
    my $self = shift;
    my $session = Lacuna->db->resultset('Lacuna::DB::Result::Session')->new({
        empire_id       => $self->id,
        date_created    => DateTime->now,
        expires         => DateTime->now->add(hours=>2), 
    })->insert;
    $self->update({last_login => DateTime->now});
    return $session;
}

sub is_password_valid {
    my ($self, $password) = @_;
    return ($self->password eq $self->encrypt_password($password)) ? 1 : 0;
}

sub encrypt_password {
    my ($class, $password) = @_;
    return Digest::SHA::sha256_base64($password);
}

sub found {
    my ($self, $home_planet) = @_;

    # lock empire
    $self->update({stage=>'finding home planet'});

    # found home planet
    $home_planet ||= $self->find_home_planet;
    $self->home_planet_id($home_planet->id);
    $self->add_essentia(100); # REMOVE BEFORE LAUNCH
    $self->stage('founded');
    $self->update;
    $self->home_planet($home_planet);
    $self->add_probe($home_planet->star_id, $home_planet->id);

    # found colony
    $home_planet->found_colony($self);
    
    # send welcome
    Lacuna::Tutorial->new(empire=>$self)->start('explore_the_ui');
    
    return $self;
}

sub find_home_planet {
    my ($self) = @_;
    my $planets = Lacuna->db->resultset('Lacuna::DB::Result::Body');
    
    # define sub searches
    my $min_inhabited = sub {
        my $axis = shift;
        return $planets->search({empire_id => { '>' => 0 } })->get_column($axis)->min;
    };
    my $max_inhabited = sub {
        my $axis = shift;
        return $planets->search({empire_id => { '>' => 0 } })->get_column($axis)->max;
    };

    # search
    my $possible_planets = $planets->search({
            usable_as_starter   => {'>', 0},
            orbit               => { between => [ $self->species->min_orbit, $self->species->max_orbit] },
            x                   => { between => [($min_inhabited->('x') - 1), ($max_inhabited->('x') + 1)] },
            y                   => { between => [($min_inhabited->('y') - 1), ($max_inhabited->('y') + 1)] },
            z                   => { between => [($min_inhabited->('z') - 1), ($max_inhabited->('z') + 1)] },
        },
        {
            order_by    => 'usable_as_starter',
            rows        => 10,
        },
    );

    # find an uncontested planet in the possible planets
    my $home_planet;
    my $cache = Lacuna->cache;
    while (my $planet = $possible_planets->next) {
        unless ($planet->is_locked) {
            $planet->lock;
            $home_planet = $planet;
            last;
        }
    }

    # didn't find one
    unless (defined $home_planet) {
        # unlock
        $self->update({stage => 'new'});
        confess [1002, 'Could not find a home planet. Try again in a few moments.'];
    }
    
    return $home_planet;
}

sub send_message {
    my ($self, %params) = @_;
    $params{from}   = $params{from} || $self;

    my $recipients = $params{recipients};
    unless (ref $recipients eq 'ARRAY' && @{$recipients}) {
        push @{$recipients}, $self->name;
    }
    my $message = Lacuna->db->resultset('Lacuna::DB::Result::Message')->new({
        date_sent   => DateTime->now,
        subject     => $params{subject},
        body        => $params{body},
        tags        => $params{tags},
        from_id     => $params{from}->id,
        from_name   => $params{from}->name,
        to_id       => $self->id,
        to_name     => $self->name,
        recipients  => $recipients,
        in_reply_to => $params{in_reply_to},
        attachments => $params{attachments},
    })->insert;
    if (exists $params{in_reply_to} && defined $params{in_reply_to} && $params{in_reply_to} ne '') {
        my $original =  Lacuna->db->resultset('Lacuna::DB::Result::Message')->find($params{in_reply_to});
        if (defined $original && !$original->has_replied) {
            $original->update({has_replied=>1});
        }
    }
    return $self;
}

sub send_predefined_message {
    my ($self, %options) = @_;
    my $path = '/data/Lacuna-Server/var/messages/'.$options{filename};
    if (open my $file, "<", $path) {
        my $message;
        {
            local $/;
            $message = <$file>;
        }
        close $file;
        unless (ref $options{params} eq 'ARRAY') {
            $options{params} = [];
        }
        my ($subject, $body) = split("~~~\n",sprintf($message, @{$options{params}}));
        chomp $subject;
        if ($options{body_prefix}) {
            $body = $options{body_prefix}.$body;
        }
        my $attachments = {};
        if ($options{attach_table}) {
            $attachments->{table} = $options{attach_table};
        }
        if ($options{attach_map}) {
            $attachments->{map} = $options{attach_map};
        }
        return $self->send_message(
            subject     => $subject,
            body        => $body,
            from        => $options{from},
            tags        => $options{tags},
            attachments => $attachments,
            );
    }
    else {
        warn "Couldn't send message using $path";
    }
}

sub lacuna_expanse_corp {
    my $self = shift;
    return Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find(1);
}

sub add_probe {
    my ($self, $star_id, $body_id) = @_;

    # add probe
    Lacuna->db->resultset('Lacuna::DB::Result::Probes')->new({
        empire_id   => $self->id,
        star_id     => $star_id,
        body_id     => $body_id,
    })->insert;
    
    # no longer an isolationist
    if ($self->is_isolationist && $star_id ne $self->home_planet->star_id) {
        $self->update({is_isolationist=>0});
    }
    
    # send notifications
    # this could be a performance problem in the future depending upon the number of probes in a star system
    my $star_name = Lacuna->db->resultset('Lacuna::DB::Result::Star')->find($star_id)->name;
    my $probes = Lacuna->db->resultset('Lacuna::DB::Result::Probes')->search({ star_id => $star_id, empire_id => {'!=', $self->id } });
    while (my $probe = $probes->next) {
        my $that_empire = $probe->empire;
        next unless defined $that_empire;
        $that_empire->send_predefined_message(
            filename    => 'probe_detected.txt',
            tags        => ['Alert'],
            from        => $that_empire,
            params      => [$star_name, $self->name],
        );
    }
    
    $self->clear_probed_stars;
    return $self;
}

has next_planet_cost => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $inflation = (101 - $self->species->political_affinity) / 100;
        my $count = scalar(@{$self->body_ids});
        my $tally = 100_000;
        for (2..$count) {
            $tally += $tally * 0.96;
        }
        return $tally;
    },
);

has happiness => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $happiness = 0;
        my @planet_ids;
        my $planet_rs = $self->planets;
        while (my $planet = $planet_rs->next) {
            $planet->tick;
            $happiness += $planet->happiness;
            push @planet_ids, $planet->id;
        }
        $self->body_ids(\@planet_ids);
    },
);

has body_ids => (
    is          => 'rw',
    clearer     => 'clear_body_ids',
    lazy        => 1,
    default     => sub {
        my $self = shift;
        return Lacuna->db->resultset('Lacuna::DB::Result::Body')->search({empire_id=>$self->id})->get_column('id')->all;
    },
);

has probed_stars => (
    is          => 'rw',
    clearer     => 'clear_probed_stars',
    lazy        => 1,
    default     => sub {
        my $self = shift;
        my $probes = $self->probes;
        my @stars;
        while ( my $probe = $probes->next ) {
            push @stars, $probe->star_id;
        }
        return \@stars;
    },
);

has count_probed_stars => (
    is          => 'rw',
    lazy        => 1,
    default     => sub {    
        my $self = shift;
        return Lacuna->db->resultset('Lacuna::DB::Result::Probes')->search({empire_id=>$self->id})->count;
    },
);

before 'delete' => sub {
    my ($self) = @_;
    my $db = $self->simpledb;
    $self->sent_messages->delete;
    $self->received_messages->delete;
    $self->medals->delete;
    $self->probes->delete;
    my $planets = $self->planets;
    while ( my $planet = $planets->next ) {
        $planet->sanitize;
    }
    if ($self->species_id != 2) {
        $self->species->delete;
    }
    $self->sessions->delete;
};

sub trigger_full_update {
    my ($self, %options) = @_;
    unless ($self->needs_full_update) {
        $self->needs_full_update(1);
        $self->update unless $options{skip_put};
    }
    return $self;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
