package Lacuna::DB::Result::Empire;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use DateTime;
use Lacuna::Util qw(format_date);
use Digest::SHA;
use List::MoreUtils qw(uniq);
use Email::Stuff;
use Email::Valid;
use UUID::Tiny ':std';
use Lacuna::Constants qw(INFLATION);


__PACKAGE__->table('empire');
__PACKAGE__->add_columns(
    name                    => { data_type => 'varchar', size => 30, is_nullable => 0 },
    stage                   => { data_type => 'varchar', size => 30, is_nullable => 0, default_value => 'new' },
    date_created            => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    self_destruct_date      => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    self_destruct_active    => { data_type => 'tinyint', is_nullable => 0, default_value => 0},
    description             => { data_type => 'text', is_nullable => 1 },
    notes                   => { data_type => 'text', is_nullable => 1 },
    home_planet_id          => { data_type => 'int',  is_nullable => 1 },
    status_message          => { data_type => 'varchar', size => 255 },
    password                => { data_type => 'char', size => 43 },
    sitter_password         => { data_type => 'varchar', size => 30 },
    email                   => { data_type => 'varchar', size => 255, is_nullable => 1 },
    city                    => { data_type => 'varchar', size => 100, is_nullable => 1 },
    country                 => { data_type => 'varchar', size => 100, is_nullable => 1 },
    skype                   => { data_type => 'varchar', size => 100, is_nullable => 1 },
    player_name             => { data_type => 'varchar', size => 100, is_nullable => 1 },
    password_recovery_key   => { data_type => 'varchar', size => 36, is_nullable => 1 },
    last_login              => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    essentia                => { data_type => 'int', default_value => 0 },
    university_level        => { data_type => 'tinyint', default_value => 0 },
    tutorial_stage          => { data_type => 'varchar', size => 30, is_nullable => 0, default_value => 'explore_the_ui' },
    tutorial_scratch        => { data_type => 'text', is_nullable => 1 },
    is_isolationist         => { data_type => 'tinyint', default_value => 1 },
    storage_boost           => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    food_boost              => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    water_boost             => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    ore_boost               => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    energy_boost            => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    happiness_boost         => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    facebook_uid            => { data_type => 'bigint', is_nullable => 1 },
    facebook_token          => { data_type => 'varchar', size => 100, is_nullable => 1 },
    alliance_id             => { data_type => 'int', is_nullable => 1 },
    species_name            => { data_type => 'varchar', size => 30, default_value => 'Human', is_nullable => 0 },
    species_description     => { data_type => 'text', is_nullable => 1 },
    min_orbit               => { data_type => 'tinyint', default_value => 3 },
    max_orbit               => { data_type => 'tinyint', default_value => 3 },
    manufacturing_affinity  => { data_type => 'tinyint', default_value => 4 }, # cost of building new stuff
    deception_affinity      => { data_type => 'tinyint', default_value => 4 }, # spying ability
    research_affinity       => { data_type => 'tinyint', default_value => 4 }, # cost of upgrading
    management_affinity     => { data_type => 'tinyint', default_value => 4 }, # speed to build
    farming_affinity        => { data_type => 'tinyint', default_value => 4 }, # food
    mining_affinity         => { data_type => 'tinyint', default_value => 4 }, # minerals
    science_affinity        => { data_type => 'tinyint', default_value => 4 }, # energy, propultion, and other tech
    environmental_affinity  => { data_type => 'tinyint', default_value => 4 }, # waste and water
    political_affinity      => { data_type => 'tinyint', default_value => 4 }, # happiness
    trade_affinity          => { data_type => 'tinyint', default_value => 4 }, # speed of cargoships, and amount of cargo hauled
    growth_affinity         => { data_type => 'tinyint', default_value => 4 }, # price and speed of colony ships, and planetary command center start level
    skip_medal_messages     => { data_type => 'tinyint', default_value => 0 },
    skip_pollution_warnings => { data_type => 'tinyint', default_value => 0 },
    skip_resource_warnings  => { data_type => 'tinyint', default_value => 0 },
    skip_happiness_warnings => { data_type => 'tinyint', default_value => 0 },
    skip_facebook_wall_posts => { data_type => 'tinyint', default_value => 0 },
    is_admin                => { data_type => 'tinyint', default_value => 0 },
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_self_destruct', fields => ['self_destruct_active','self_destruct_date']);
    $sqlt_table->add_index(name => 'idx_password_recovery_key', fields => ['password_recovery_key']);
    $sqlt_table->add_index(name => 'idx_inactives', fields => ['last_login,','self_destruct_active']);
    $sqlt_table->add_index(name => 'idx_admins', fields => ['name,','is_admin']);
}


__PACKAGE__->belongs_to('alliance', 'Lacuna::DB::Result::Alliance', 'alliance_id', { on_delete => 'set null' });
__PACKAGE__->belongs_to('home_planet', 'Lacuna::DB::Result::Map::Body', 'home_planet_id');
__PACKAGE__->has_many('planets', 'Lacuna::DB::Result::Map::Body', 'empire_id');
__PACKAGE__->has_many('sent_messages', 'Lacuna::DB::Result::Message', 'from_id');
__PACKAGE__->has_many('received_messages', 'Lacuna::DB::Result::Message', 'to_id');
__PACKAGE__->has_many('medals', 'Lacuna::DB::Result::Medals', 'empire_id');
__PACKAGE__->has_many('probes', 'Lacuna::DB::Result::Probes', 'empire_id');

sub self_destruct_date_formatted {
    my $self = shift;
    return format_date($self->self_destruct_date);
}

has current_session => (
    is                  => 'rw',
    predicate           => 'has_current_session',
);


sub update_species {
    my ($self, $me) = @_;
    $self->species_name($me->{name});
    $self->species_description($me->{description});
    $self->min_orbit($me->{min_orbit});
    $self->max_orbit($me->{max_orbit});
    $self->manufacturing_affinity($me->{manufacturing_affinity});
    $self->deception_affinity($me->{deception_affinity});
    $self->research_affinity($me->{research_affinity});
    $self->management_affinity($me->{management_affinity});
    $self->farming_affinity($me->{farming_affinity});
    $self->mining_affinity($me->{mining_affinity});
    $self->science_affinity($me->{science_affinity});
    $self->environmental_affinity($me->{environmental_affinity});
    $self->political_affinity($me->{political_affinity});
    $self->trade_affinity($me->{trade_affinity});
    $self->growth_affinity($me->{growth_affinity});
    return $self;
}

sub determine_species_limits {
    my ($self) = @_;
    my @colony_ids = $self->planets->get_column('id')->all;
    my $min_pcc_level = Lacuna->db->resultset('Lacuna::DB::Result::Building')->search({ body_id => { in => \@colony_ids }, class => 'Lacuna::DB::Result::Building::PlanetaryCommand' })->get_column('level')->min;
    my $colonies = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({ empire_id => $self->id });
    my $min_orbit = $colonies->get_column('orbit')->min;
    my $max_orbit = $colonies->get_column('orbit')->max;
    my $reason;
    if ($self->university_level > 19) {
        $reason = 'Your university research level is too high to redefine your species. Build a Genetics Lab instead.';
    }
    elsif (Lacuna->cache->get('redefine_species_timeout', $self->id)) {
        $reason = 'You have already redefined your species in the past 30 days.';
    }
    return {
        essentia_cost   => 100,
        min_growth      => ($min_pcc_level > $self->growth_affinity) ? $self->growth_affinity : $min_pcc_level,
        min_orbit       => $min_orbit,
        max_orbit       => $max_orbit,
        can             => ($reason) ? 0 : 1,
        reason          => $reason,
    };
}

sub has_medal {
    my ($self, $type) = @_;
    return Lacuna->db->resultset('Lacuna::DB::Result::Medals')->search({empire_id => $self->id, type => $type},{rows=>1})->single;
}

sub add_medal {
    my ($self, $type, $send_message) = @_;
    my $medal = $self->has_medal($type);
    if ($medal) {
        $medal->times_earned( $medal->times_earned + 1);
        $medal->update;
    }
    else {
        $medal = Lacuna->db->resultset('Lacuna::DB::Result::Medals')->new({
            datestamp   => DateTime->now,
            public      => 1,
            empire_id   => $self->id,
            type        => $type,
            times_earned => 1,
        });
        $medal->insert;
        $send_message = 1;
    }
    if ($send_message && !$self->skip_medal_messages) {
        my $name = $medal->name;
        my $image = Lacuna->config->get('feeds/surl').'assets/medal/'.$type.'.png';
        $self->send_predefined_message(
            tags        => ['Medal'],
            filename    => 'medal.txt',
            params      => [$name, $name, $self->name],
            attachments => {
                image => {
                    title   => $name,
                    url     => $image,
                }
            },
        );
    }
    return $medal;
}

sub spend_essentia {
    my ($self, $value, $note, $transaction_id) = @_;
    $self->essentia( $self->essentia - $value );
    Lacuna->db->resultset('Lacuna::DB::Result::Log::Essentia')->new({
        empire_id       => $self->id,
        empire_name     => $self->name,
        amount          => $value * -1,
        description     => $note,
        api_key         => (defined $self->current_session) ? $self->current_session->api_key : undef,
        transaction_id  => $transaction_id,
    })->insert;
    return $self;
}

sub add_essentia {
    my ($self, $value, $note, $transaction_id) = @_;
    $self->essentia( $self->essentia + $value );
    Lacuna->db->resultset('Lacuna::DB::Result::Log::Essentia')->new({
        empire_id       => $self->id,
        empire_name     => $self->name,
        amount          => $value,
        description     => $note,
        transaction_id  => $transaction_id,
        api_key         => (defined $self->current_session) ? $self->current_session->api_key : undef,
    })->insert;
    return $self;
}

sub get_new_message_count {
    my $self = shift;
    return Lacuna->db->resultset('Lacuna::DB::Result::Message')->search({
        to_id           => $self->id,
        has_archived    => 0,
        has_read        => 0,
    })->count;
}

sub get_newest_message {
    my $self = shift;
    my $message = Lacuna->db->resultset('Lacuna::DB::Result::Message')->search(
        {
            to_id           => $self->id,
            has_archived    => 0,
            has_read        => 0,
        },
        {
            order_by        => { -desc => 'date_sent' },
            rows            => 1,
        }
    )->single;
    if (defined $message) {
    	return { id => $message->id, date_received => $message->date_sent_formatted, subject => $message->subject }; 
    }
    else {
        return undef;
    }
}

sub get_status {
    my ($self) = @_;
    my $planet_rs = $self->planets;
    my %planets;
    my @planet_ids;
    while (my $planet = $planet_rs->next) {
        $planets{$planet->id} = $planet->name;
    }
    my $status = {
        is_isolationist     => $self->is_isolationist,
        status_message      => $self->status_message,
        name                => $self->name,
        id                  => $self->id,
        essentia            => $self->essentia,
        has_new_messages    => $self->get_new_message_count,
        most_recent_message => $self->get_newest_message,
        home_planet_id      => $self->home_planet_id,
        planets             => \%planets,
        self_destruct_active=> $self->self_destruct_active,
        self_destruct_date  => $self->self_destruct_date_formatted,
    };
    return $status;
}

sub start_session {
    my ($self, $options) = @_;
    $self->last_login(DateTime->now);
    $self->update;
    return Lacuna::Session->new->start($self, $options);
}

sub is_password_valid {
    my ($self, $password) = @_;
    return (defined $password && $password ne '' && $self->password eq $self->encrypt_password($password)) ? 1 : 0;
}

sub encrypt_password {
    my ($class, $password) = @_;
    return Digest::SHA::sha256_base64($password);
}


sub attach_invite_code {
    my ($self, $invite_code) = @_;
    my $invites = Lacuna->db->resultset('Lacuna::DB::Result::Invite');
    if (defined $invite_code && $invite_code ne '') {
        my $invite = $invites->search(
            {code    => $invite_code },
            {rows => 1}
        )->single;
        if (defined $invite) {
            if ($invite->invitee_id) {
                $invite = $invite->copy({invitee_id => $self->id, email => $self->email, accept_date => DateTime->now});
            }
            else {
                $invite->invitee_id($self->id);
                $invite->accept_date(DateTime->now);
                $invite->update;
            }
            Lacuna->cache->increment('friends_accepted', format_date(undef,'%F'), 1, 60 * 60 * 26);
            my $inviter = $invite->inviter;
            if (defined $inviter) { # they may have deleted
                my $accepts = $invites->search({inviter_id => $invite->inviter_id, invitee_id => {'>' => 0}})->count;
                if ($accepts == 3) { 
                    $inviter->home_planet->add_plan('Lacuna::DB::Result::Building::Permanent::Crater',1);
                    $inviter->send_predefined_message(
                        tags        => ['Correspondence'],
                        filename    => 'thank_you_for_inviting_friends.txt',
                        params      => [$invite->email, $self->id, $self->name, $accepts, 'a crater plan'],
                        from        => $self->lacuna_expanse_corp,
                    );
                }                
                elsif ($accepts == 4) { 
                    $inviter->home_planet->add_plan('Lacuna::DB::Result::Building::Permanent::RockyOutcrop',1);
                    $inviter->send_predefined_message(
                        tags        => ['Correspondence'],
                        filename    => 'thank_you_for_inviting_friends.txt',
                        params      => [$invite->email, $self->id, $self->name, $accepts, 'a rocky outcropping plan'],
                        from        => $self->lacuna_expanse_corp,
                    );
                }                
                elsif ($accepts == 5) { 
                    $inviter->home_planet->add_plan('Lacuna::DB::Result::Building::Permanent::Lake',1);
                    $inviter->send_predefined_message(
                        tags        => ['Correspondence'],
                        filename    => 'thank_you_for_inviting_friends.txt',
                        params      => [$invite->email, $self->id, $self->name, $accepts, 'a lake plan'],
                        from        => $self->lacuna_expanse_corp,
                    );
                }                
                elsif ($accepts == 6) { 
                    $inviter->home_planet->add_plan('Lacuna::DB::Result::Building::Permanent::Sand',1);
                    $inviter->send_predefined_message(
                        tags        => ['Correspondence'],
                        filename    => 'thank_you_for_inviting_friends.txt',
                        params      => [$invite->email, $self->id, $self->name, $accepts, 'a sand plan'],
                        from        => $self->lacuna_expanse_corp,
                    );
                }                             
                elsif ($accepts == 7) { 
                    $inviter->home_planet->add_plan('Lacuna::DB::Result::Building::Permanent::Grove',1);
                    $inviter->send_predefined_message(
                        tags        => ['Correspondence'],
                        filename    => 'thank_you_for_inviting_friends.txt',
                        params      => [$invite->email, $self->id, $self->name, $accepts, 'a grove of trees plan'],
                        from        => $self->lacuna_expanse_corp,
                    );
                }                
                elsif ($accepts == 8) { 
                    $inviter->home_planet->add_plan('Lacuna::DB::Result::Building::Permanent::Lagoon',1);
                    $inviter->send_predefined_message(
                        tags        => ['Correspondence'],
                        filename    => 'thank_you_for_inviting_friends.txt',
                        params      => [$invite->email, $self->id, $self->name, $accepts, 'a lagoon plan'],
                        from        => $self->lacuna_expanse_corp,
                    );
                }                
                elsif ($accepts == 10) { 
                    for my $i (1..13) {
                        $inviter->home_planet->add_plan('Lacuna::DB::Result::Building::Permanent::Beach'.$i,1);
                    }
                    $inviter->send_predefined_message(
                        tags        => ['Correspondence'],
                        filename    => 'thank_you_for_inviting_friends.txt',
                        params      => [$invite->email, $self->id, $self->name, $accepts, 'a complete set of beach plans'],
                        from        => $self->lacuna_expanse_corp,
                    );
                }
                else {
                    $inviter->send_predefined_message(
                        tags        => ['Correspondence'],
                        filename    => 'friend_joined.txt',
                        params      => [$invite->email, $self->id, $self->name],
                        from        => $self->lacuna_expanse_corp,
                    );
                }
            }
        }
    }
}

sub found {
    my ($self, $home_planet) = @_;

    # lock empire
    $self->update({stage=>'finding home planet'});

    # found home planet
    $home_planet ||= $self->find_home_planet;
    $self->tutorial_scratch($home_planet->name);
    $self->home_planet_id($home_planet->id);
    $self->stage('founded');
    $self->update;
    $self->home_planet($home_planet);
    $self->add_probe($home_planet->star_id, $home_planet->id);

    # found colony
    $home_planet->found_colony($self);

    # send welcome
    return Lacuna::Tutorial->new(empire=>$self)->start('explore_the_ui');
}


sub find_home_planet {
    my ($self) = @_;
    my $planets = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body');
    my %search = (
        usable_as_starter_enabled   => 1,
        orbit                       => { between => [ $self->min_orbit, $self->max_orbit] },
    );
    
    # determine search area
    my $invite = Lacuna->db->resultset('Lacuna::DB::Result::Invite')->search({invitee_id => $self->id},{rows=>1})->single;
    if (defined $invite) {
        $search{zone} = $invite->zone;
        # other possible solution
        #   (SQRT( POW(5-x,2) + POW(8-y,2) )) as distance
        # then order by distance
    }

    # search
    my $possible_planets = $planets->search(\%search, {order_by => { -desc => ['usable_as_starter'] }});

    # find an uncontested planet in the possible planets
    my $home_planet;
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
        if (defined $invite) {
            $invite->update({invitee_id => undef});
        }
        confess [1002, 'Could not find a home planet. Try again in a few moments.'];
    }
    
    return $home_planet;
}

sub get_invite_friend_url {
    my ($self) = @_;
    my $code = create_uuid_as_string(UUID_MD5, $self->id);
    my $invites = Lacuna->db->resultset('Lacuna::DB::Result::Invite');
    my $invite = $invites->search({code => $code},{rows=>1})->single;
    unless (defined $invite) {
        $invites->new({
            inviter_id  => $self->id,
            code        => $code,
            zone        => $self->home_planet->zone,
        })->insert;
    }
    return Lacuna->config->get('server_url').'#referral='.$code;
}

sub invite_friend {
    my ($self, $email, $custom_message) = @_;
    $custom_message ||= "I'm having a great time with this new game called Lacuna Expanse. Come play with me.";
    unless (Email::Valid->address($email)) {
        confess [1009, $email.' does not appear to be a valid email address.'];
    }
    my $invites = Lacuna->db->resultset('Lacuna::DB::Result::Invite');
    if ($invites->search({email => $email, inviter_id => $self->id })->count) {
        confess [1009, 'You have already invited '.$email.'.'];
    }
    my $code = create_uuid_as_string(UUID_V4);
    $invites->new({
        inviter_id  => $self->id,
        code        => $code,
        zone        => $self->home_planet->zone,
        email       => $email,
    })->insert;
    Lacuna->cache->increment('friends_invited', format_date(undef,'%F'), 1, 60 * 60 * 26);
    my $message = sprintf "%s\n\nMy name in the game is %s. Use the code below when you register and you'll be placed near me.\n\n%s\n\n%s\n\nIf you are unfamiliar with The Lacuna Expanse, visit the web site at: http://www.lacunaexpanse.com/",
        $custom_message,
        $self->name,
        $code,
        Lacuna->config->get('server_url').'#referral='.$code;
    Email::Stuff->from($self->email)
        ->to($email)
        ->subject('Come Play With Me')
        ->text_body($message)
        ->send;
}

sub send_email {
    my ($self, $subject, $message) = @_;
    return unless ($self->email);
    Email::Stuff->from('"The Lacuna Expanse" <noreply@lacunaexpanse.com>')
        ->to($self->email)
        ->subject($subject)
        ->text_body($message)
        ->send;
}

sub send_message {
    my ($self, %params) = @_;
    $params{from}   ||= $self;

    my $recipients = $params{recipients};
    unless (ref $recipients eq 'ARRAY' && @{$recipients}) {
        push @{$recipients}, $self->name;
    }
    my $message = Lacuna->db->resultset('Lacuna::DB::Result::Message')->new({
        date_sent   => DateTime->now,
        subject     => $params{subject},
        body        => $params{body},
        tag         => $params{tag} || $params{tags}->[0],
        from_id     => $params{from}->id,
        from_name   => $params{from}->name,
        to_id       => $self->id,
        to_name     => $self->name,
        recipients  => $recipients,
        in_reply_to => $params{in_reply_to},
        repeat_check=> $params{repeat_check},
        attachments => $params{attachments},
    })->insert;
    if (exists $params{in_reply_to} && defined $params{in_reply_to} && $params{in_reply_to} ne '') {
        my $original =  Lacuna->db->resultset('Lacuna::DB::Result::Message')->find($params{in_reply_to});
        if (defined $original && !$original->has_replied) {
            $original->update({has_replied=>1});
        }
    }
    return $message;
}

sub check_for_repeat_message {
    my ($self, $repeat) = @_;
    my $six_hours_ago = DateTime->now->subtract(hours=>6);
    return $self->received_messages->search_literal(
        'repeat_check = ? and ( date_sent >= ? or (has_read = 0 and has_archived = 0 ))',
        $repeat,
        $six_hours_ago->ymd.' '.$six_hours_ago->hms,
    )->count;
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
        return $self->send_message(
            subject     => $subject,
            body        => $body,
            from        => $options{from},
            repeat_check=> $options{repeat_check},
            tags        => $options{tags},
            attachments => $options{attachments},
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
        alliance_id => $self->alliance_id,
    })->insert;
    
    # send notifications
    # this could be a performance problem in the future depending upon the number of probes in a star system
    my $star = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->find($star_id);
    my $probes = Lacuna->db->resultset('Lacuna::DB::Result::Probes')->search({ star_id => $star_id, empire_id => {'!=', $self->id } });
    while (my $probe = $probes->next) {
        my $that_empire = $probe->empire;
        next unless defined $that_empire;
        $that_empire->send_predefined_message(
            filename    => 'probe_detected.txt',
            tags        => ['Alert'],
            from        => $that_empire,
            params      => [$star->x, $star->y, $star->name, $self->id, $self->name],
        );
    }
    
    $self->clear_probed_stars;
    return $self;
}

sub next_colony_cost {
    my ($self) = @_;
    my $count = $self->planets->count;
    $count += Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        { type=> { in => [qw(colony_ship short_range_colony_ship)]}, task=>'travelling', 'body.empire_id' => $self->id},
        { join => 'body' }
    )->count;
    my $inflation = INFLATION - ($self->political_affinity / 100);
    my $tally = 100_000;
    for (2..$count) {
        $tally += $tally * $inflation;
    }
    return sprintf('%.0f', $tally);
}

has probed_stars => (
    is          => 'rw',
    clearer     => 'clear_probed_stars',
    lazy        => 1,
    default     => sub {
        my $self = shift;
        my %search = (
            empire_id => $self->id,
        );
        if ($self->alliance_id) {
            %search = (
                alliance_id => $self->alliance_id,
            );
        }
        my @stars = Lacuna->db->resultset('Lacuna::DB::Result::Probes')->search(\%search)->get_column('star_id')->all;
        return \@stars;
    },
);

has count_probed_stars => (
    is          => 'rw',
    lazy        => 1,
    default     => sub {    
        my $self = shift;
        return $self->probes->count;
    },
);

before 'delete' => sub {
    my ($self) = @_;
    Lacuna->db->resultset('Lacuna::DB::Result::Invite')->search({ -or => {invitee_id => $self->id, inviter_id => $self->id }})->delete;
    $self->probes->delete;
    Lacuna->db->resultset('Lacuna::DB::Result::AllianceInvite')->search({empire_id => $self->id})->delete;
    if ($self->alliance_id) {
        my $alliance = $self->alliance;
        if ($alliance->leader_id == $self->id) {
            $alliance->delete;
        }
    }
    $self->sent_messages->delete;
    $self->received_messages->delete;
    $self->medals->delete;
    my $planets = $self->planets;
    while ( my $planet = $planets->next ) {
        $planet->sanitize;
    }
    my $essentia_log = Lacuna->db->resultset('Lacuna::DB::Result::Log::Essentia');
    my $essentia_code;
    my $sum = $self->essentia - $essentia_log->search({empire_id => $self->id, description => 'tutorial' })->get_column('amount')->sum;
    if ($sum > 0 && $self->email) {
        $essentia_code = create_uuid_as_string(UUID_V4);
        my $code = Lacuna->db->resultset('Lacuna::DB::Result::EssentiaCode')->new({
            code            => $essentia_code,
            date_created    => DateTime->now,
            description     => $self->name .' deleted',
            amount          => $sum,
        })->insert;
        $self->send_email(
            'Essentia Code',
            sprintf("When your account was deleted you had %s essentia remaining. You can redeem it using the code %s on %s from any other account.",
                $code->amount,
                $essentia_code,
                Lacuna->config->get('server_url'),
            ),
        );
    }
    $essentia_log->new({
        empire_id       => $self->id,
        empire_name     => $self->name,
        amount          => $self->essentia * -1,
        description     => 'empire deleted',
        transaction_id  => $essentia_code,
    })->insert;
};

sub enable_self_destruct {
    my $self = shift;
    $self->self_destruct_active(1);
    $self->self_destruct_date(DateTime->now->add(hours => 24));
    $self->update;
    my $subject = 'Your Empire Will Self Destruct In...';
    $self->send_email(
        $subject,
        sprintf("Your empire, %s, will self destruct in 24 hours unless you log in and click on the disable self destruct icon.\n\n%s",
            $self->name,
            Lacuna->config->get('server_url'),
        ),
    );
    $self->send_message(subject => $subject, body => 'Your empire will self destruct in 24 hours unless you click on the disable self destruct icon.');
    return $self;
}

sub disable_self_destruct {
    my $self = shift;
    $self->self_destruct_active(0);
    $self->update;
    return $self;
}

sub redeem_essentia_code {
    my ($self, $code_string) = @_;
    unless (defined $code_string && $code_string ne '') {
        confess [1002,'You must specify an essentia code in order to redeem it.'];
    }
    my $code = Lacuna->db->resultset('Lacuna::DB::Result::EssentiaCode')->search({code => $code_string}, {rows=>1})->single;
    unless (defined $code) {
        confess [1002, 'The essentia code you specified is invalid.'];
    }
    if ($code->used) {
        confess [1010, 'The essentia code you specified has already been redeemed.'];
    }
    $self->add_essentia($code->amount, 'Essentia Code Redemption', $code->code);
    $self->update;
    $code->used(1);
    $code->update;
    return $self;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
