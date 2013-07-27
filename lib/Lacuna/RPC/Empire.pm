package Lacuna::RPC::Empire;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC';
use Lacuna::Util qw(format_date randint);
use DateTime;
use String::Random qw(random_string);
use UUID::Tiny ':std';
use Time::HiRes;
use Text::CSV_XS;
use Captcha::reCAPTCHA;


# Find an empire by name
#
sub find_empire {
    my ($self, $args) = @_;

    confess [1019, 'You must call using named arguments.'] if ref($args) ne "HASH";
    confess [1009, 'Empire name too short. Your search must be at least 3 characters.'] if length($args->{name}) < 3;
    
    my $empire = $self->get_empire_by_session($args->{session_id});

    my $empires = Lacuna->db->resultset('Empire')->search({
        name    => {'like' => $args->{name}.'%'},
    },{
        rows    => 100
    });
    my @list_of_empires;
    my $limit = 100;
    while (my $emp = $empires->next && $limit) {
        push @list_of_empires, {
            id      => $emp->id,
            name    => $emp->name,
        };
        $limit--;
    }
    return {
        empires => \@list_of_empires, 
        status  => $self->format_status($empire) };
}

# Check if a proposed empire name is both valid and not already taken
#
sub is_name_available {
    my ($self, $args) = @_;
    
    confess [1019, 'You must call using named arguments.'] if ref($args) ne "HASH";
    $self->is_name_valid($args->{name});
    $self->is_name_unique($args->{name});
    return 1; 
}

sub is_name_valid {
    my ($self, $name) = @_;
    Lacuna::Verify->new(content=>\$name, throws=>[1000,'Empire name is invalid.', 'name'])
        ->length_lt(31)
        ->length_gt(2)
        ->not_empty
        ->no_padding
        ->no_restricted_chars
        ->no_profanity
        ->no_bad_words;
    return 1; 
}

sub is_name_unique {
    my ($self, $name) = @_;
    if (Lacuna->db->resultset('Empire')->search({name=>$name})->count) {
        confess [1000, 'Empire name is in use by another player.', 'name'];
    }
    return 1;
}

# Logout and lose the session
#
sub logout {
    my ($self, $args) = @_;

    confess [1019, 'You must call using named arguments.'] if ref($args) ne "HASH";
    $self->get_session($args->{session_id})->end;
    return 1;
}

# Login with credentials
# 
sub login {
    my ($self, $plack_request, $args) = @_;

    confess [1019, 'You must call using named arguments.'] if ref($args) ne "HASH";
    
    unless ($args->{api_key}) {
        confess [1002, 'You need an API Key.'];
    }
    my $empire = Lacuna->db->resultset('Empire')->search({
        name    =>  $args->{name},
    })->next;
    unless (defined $empire) {
         confess [1002, 'Empire does not exist.', $args->{name}];
    }
    my $throttle = Lacuna->config->get('rpc_throttle') || 30;
    if ($empire->rpc_rate > $throttle) {
        Lacuna->cache->increment('rpc_limit_'.format_date(undef,'%d'), $empire->id, 1, 60 * 60 * 30);
        confess [1010, 'Slow down, '.$empire->name.'! No more than '.$throttle.' requests per minute.'];
    }
    my $max = Lacuna->config->get('rpc_limit') || 2500;
    if ($empire->rpc_count > $max) {
        confess [1010, $empire->name.' has already made the maximum number of requests ('.$max.') you can make for one day.'];
    }
    if ($empire->is_password_valid($args->{password})) {
        if ($empire->stage eq 'new') {
            confess [1100, "Your empire has not been completely created. You must complete it in order to play the game.", { empire_id => $empire->id } ];
        }
        else {
            return { session_id => $empire->start_session({
                api_key     => $args->{api_key}, 
                request     => $plack_request,
                })->id, status => $self->format_status($empire) };
        }
    }
    else {
        if ($args->{password} ne '' && $empire->sitter_password eq $args->{password}) {
            return {
                session_id  => $empire->start_session({
                    api_key     => $args->{api_key}, 
                    request     => $plack_request, 
                    is_sitter   => 1,
                })->id, 
                status      => $self->format_status($empire),
            };
        }
        else {
            confess [1004, 'Password incorrect.', $args->{password}];            
        }
    }
}

# Change the empires password
#
sub change_password {
    my ($self, $args) = @_;

    confess [1019, 'You must call using named arguments.'] if ref($args) ne "HASH";

    my $session_id = $args->{session_id};
    my $current_password = $args->{current_password};
    my $password1 = $args->{password1};
    my $password2 = $args->{password2};

    Lacuna::Verify->new(content=>\$password1, throws=>[1001,'Invalid password.', $password1])
        ->length_gt(5)
        ->eq($password2);

    my $empire = $self->get_empire_by_session($session_id);
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot modify the main account password.'];
    }
    
    $empire->password($empire->encrypt_password($password1));
    $empire->update;
    return { status => $self->format_status($empire) };
}

# Allow the user to request that a new password is sent
#
sub send_password_reset_message {
    my ($self, $args) = @_;
    
    confess [1019, 'You must call using named arguments.'] if ref($args) ne "HASH";
        
    my $empire;
    my $empires = Lacuna->db->resultset('Empire');
    if (exists $args->{empire_id} && $args->{empire_id} ne '') {
        $empire = $empires->find($args->{empire_id});
    }
    elsif (exists $args->{empire_name}) {
        $empire = $empires->search({ name => $args->{empire_name} }, { rows => 1 })->single;
    }
    elsif (exists $args->{email}) {
        $empire = $empires->search({ email => $args->{email} }, { rows => 1 })->single;
    }
    unless (defined $empire) {
        confess [1002, 'Empire not found.'];
    }
    unless ($empire->email) {
        confess [1002, 'That empire has no email address specified.'];
    }
    $empire->password_recovery_key(create_uuid_as_string(UUID_V4));
    $empire->update;
    
    my $message = "Use the key or the link below to reset the password for %s.\n\nKey: %s\n\n%s#reset_password=%s";
    $empire->send_email(
        'Reset Your Password',
        sprintf($message, $empire->name, $empire->password_recovery_key, Lacuna->config->get('server_url'), $empire->password_recovery_key),
    );
    return { sent => 1 };
}

# Respond to a request to reset the password
#
sub reset_password {
    my ($self, $plack_request, $args) = @_;

    confess [1019, 'You must call using named arguments.'] if ref($args) ne "HASH";

    my $key         = $args->{reset_key};
    my $password1   = $args->{password1};
    my $password2   = $args->{password2};
    my $api_key     = $args->{api_key};

    unless ($api_key) {
        confess [1002, 'You need an API Key.'];
    }
    # verify
    unless (defined $key && $key ne '') {
        confess [1002, 'You need a key to reset a password.'];
    }
    my $empire = Lacuna->db->resultset('Empire')->search({password_recovery_key => $key}, { rows=>1 })->single;
    unless (defined $empire) {
        confess [1002, 'The key you provided is invalid. Password not reset.'];
    }
    Lacuna::Verify->new(content=>\$password1, throws=>[1001,'Invalid password.', $password1])
        ->length_gt(5)
        ->eq($password2);
    
    # reset
    $empire->password($empire->encrypt_password($password1));
    $empire->password_recovery_key('');
    $empire->update;
    
    # authenticate
    return { session_id => $empire->start_session({ api_key => $api_key, request => $plack_request })->id, status => $self->format_status($empire) };
}


# Create, defined species and found all in one go
# 
sub create {
    my ($self, $plack_request, $args) = @_;

    # TODO need to understand how we integrate Facebook!
    #

    # verify password
    Lacuna::Verify->new(content=>\$args->{password}, throws=>[1001,'Invalid password. It must be at least 6 characters and both passwords must match.', 'password'])
        ->length_gt(5)
        ->eq($args->{password1});
                                    
    # verify username
    $self->is_name_unique($args->{name});
    $self->is_name_valid($args->{name});

    # verify email
    if (exists $args->{email} && $args->{email} ne '') {
        Lacuna::Verify->new(content=>\$args->{email}, throws=>[1005,'The email address specified does not look valid.', 'email'])
            ->is_email;
        if (Lacuna->db->resultset('Empire')->search({email=>$args->{email}})->count > 0) {
            confess [1005, 'That email address is already in use by another empire.', 'email'];
        }
    }

    $self->vet_species($args);

    # verify captcha
    $self->validate_recaptcha($plack_request, $args->{captcha_challenge}, $args->{captcha_response});
    my $now = DateTime->now();

    my $empire = Lacuna->db->resultset('Empire')->create({
        name                    => $args->{name},
        stage                   => 'new',
        date_created            => $now,
        description             => '',          # We don't capture the empire description during empire-create any more
        password                => Lacuna::DB::Result::Empire->encrypt_password($args->{password}),
        sitter_password         => random_string('CC.c!ccn'),
        status_message          => 'Making Lacuna a better Expanse.',
        email                   => $args->{email},
        last_login              => $now,
        species_name            => $args->{species_name},
        species_description     => $args->{species_description},
        min_orbit               => $args->{species_min_orbit},
        max_orbit               => $args->{species_max_orbit},
        manufacturing_affinity  => $args->{species_manufacturing},
        deception_affinity      => $args->{species_deception},
        research_affinity       => $args->{species_research},
        management_affinity     => $args->{species_management},
        farming_affinity        => $args->{species_farming},
        mining_affinity         => $args->{species_mining},
        science_affinity        => $args->{species_science},
        environmental_affinity  => $args->{species_environmental},
        political_affinity      => $args->{species_political},
        trade_affinity          => $args->{species_trade},
        growth_affinity         => $args->{species_growth},
    });
    Lacuna->cache->increment('empires_created', format_date(undef,'%F'), 1, 60 * 60 * 26);

    # handle invitation
    $empire->attach_invite_code($args->{invite_code});

    my $welcome = $empire->found;

    return {
        session_id          => $empire->start_session({ api_key => $args->{api_key}, request => $plack_request })->id,
        status              => $self->format_status($empire),
        welcome_message_id  => $welcome->id,
    }
}

# Validate the recaptcha
#
sub validate_recaptcha {
    my ($self, $plack_request, $challange, $response) = @_;

    my $c = Captcha::reCAPTCHA->new;
#    print STDERR "CHALLANGE: [$challange] RESPONSE [$response] ADDRESS [".$plack_request->address."]\n";
    my $result = $c->check_answer(
        Lacuna->config->get('recaptcha/private_key'),
        $plack_request->address,
        $challange,
        $response
    );
    if ($result->{is_valid}) {
        return 1;
    }
    confess [1014, 'Captcha not valid.', $result->{error}];
}

# Get  the status of the empire
#
sub get_status {
    my ($self, $args) = @_;

    confess [1019, 'You must call using named arguments.'] if ref($args) ne "HASH";

    return $self->format_status($self->get_empire_by_session($args->{session_id}));
}


# View your own (private) profile
#
sub get_own_profile {
    my ($self, $args) = @_;

    confess [1019, 'You must call using named arguments.'] if ref($args) ne "HASH";

    my $session_id = $args->{session_id};

    my $empire = $self->get_empire_by_session($session_id);
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot modify preferences.'];
    }
    my $my_medals;
    my $medals = $empire->medals;
    while (my $medal = $medals->next) {
        my $m = {
            id              => $medal->id,
            name            => $medal->name,
            image           => $medal->image,
            date            => $medal->format_datestamp,
            public          => $medal->public,
            times_earned    => $medal->times_earned,
        };
        push @$my_medals, $m;
    }
    my %out = (
        id                          => $empire->id,
        name                        => $empire->name,
        description                 => $empire->description,
        notes                       => $empire->notes,
        status_message              => $empire->status_message,
        sitter_password             => $empire->sitter_password,
        email                       => $empire->email,
        city                        => $empire->city,
        country                     => $empire->country,
        skype                       => $empire->skype,
        player_name                 => $empire->player_name,
        skip_medal_messages         => $empire->skip_medal_messages,
        skip_pollution_warnings     => $empire->skip_pollution_warnings,
        skip_resource_warnings      => $empire->skip_resource_warnings,
        skip_happiness_warnings     => $empire->skip_happiness_warnings,
        skip_facebook_wall_posts    => $empire->skip_facebook_wall_posts,
        medals                      => $my_medals,
        skip_found_nothing          => $empire->skip_found_nothing,
        skip_excavator_resources    => $empire->skip_excavator_resources,
        skip_excavator_glyph        => $empire->skip_excavator_glyph,
        skip_excavator_plan         => $empire->skip_excavator_plan,
        skip_excavator_artifact     => $empire->skip_excavator_artifact,
        skip_excavator_destroyed    => $empire->skip_excavator_destroyed,
        skip_excavator_replace_msg  => $empire->skip_excavator_replace_msg,
        dont_replace_excavator      => $empire->dont_replace_excavator,
        skip_spy_recovery           => $empire->skip_spy_recovery,
        skip_probe_detected         => $empire->skip_probe_detected,
        skip_attack_messages        => $empire->skip_attack_messages,
    );

    return { own_profile => \%out, status => $self->format_status($empire) };    
}

sub edit_profile {
    my ($self, $args) = @_;
    
    confess [1019, 'You must call using named arguments.'] if ref($args) ne "HASH";

    my $session_id = $args->{session_id};
    my $empire = $self->get_empire_by_session($session_id);
    
    # preferences
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot modify preferences.'];
    }
    if (exists $args->{description}) {
        Lacuna::Verify->new(content=>\$args->{description}, throws=>[1005,'Description must be less than 1024 characters and cannot contain special characters or profanity.', 'description'])
            ->length_lt(1025)
            ->no_restricted_chars
            ->no_profanity
            ->no_bad_words;
        $empire->description($args->{description});
        if ($empire->tutorial_stage ne 'turing') {
            Lacuna::Tutorial->new(empire=>$empire)->finish;
        }
    }
    if (exists $args->{notes}) {
        Lacuna::Verify->new(content=>\$args->{notes}, throws=>[1005,'Notes must be less than 1024 characters and cannot contain special characters or profanity.', 'notes'])
            ->length_lt(1025)
            ->no_restricted_chars
            ->no_profanity
            ->no_bad_words;
        $empire->notes($args->{notes});
    }
    if (exists $args->{status_message}) {
        Lacuna::Verify->new(content=>\$args->{status_message}, throws=>[1005,'Status cannot be empty, must be no longer than 100 characters, and cannot contain special characters or profanity.', 'status_message'])
            ->length_lt(101)
            ->not_empty
            ->no_restricted_chars
            ->no_profanity
            ->no_bad_words;
        $empire->status_message($args->{status_message});
    }
    if (exists $args->{sitter_password}) {
        Lacuna::Verify->new(content=>\$args->{sitter_password}, throws=>[1005,'Sitter password must be between 6 and 30 characters.', 'sitter_password'])
            ->length_lt(31)
            ->length_gt(5);
        $empire->sitter_password($args->{sitter_password});
    }
    if (exists $args->{city}) {
        Lacuna::Verify->new(content=>\$args->{city}, throws=>[1005,'City must be no longer than 100 characters, and cannot contain special characters or profanity.', 'city'])
            ->length_lt(101)
            ->no_restricted_chars
            ->no_profanity
            ->no_bad_words;
        $empire->city($args->{city});
    }
    if (exists $args->{country}) {
        Lacuna::Verify->new(content=>\$args->{country}, throws=>[1005,'Country must be no longer than 100 characters, and cannot contain special characters or profanity.', 'country'])
            ->length_lt(101)
            ->no_restricted_chars
            ->no_profanity
            ->no_bad_words;
        $empire->country($args->{country});
    }
    if (exists $args->{player_name}) {
        Lacuna::Verify->new(content=>\$args->{player_name}, throws=>[1005,'Player name must be no longer than 100 characters, and cannot contain special characters or profanity.', 'player_name'])
            ->length_lt(101)
            ->no_restricted_chars
            ->no_profanity
            ->no_bad_words;
        $empire->player_name($args->{player_name});
    }
    for my $skip (qw(skip_medal_messages skip_happiness_warnings skip_facebook_wall_posts skip_resource_warnings skip_pollution_warnings
            skip_found_nothing skip_excavator_replace_msg skip_excavator_resources skip_excavator_glyph skip_excavator_plan skip_excavator_artifact
            skip_excavator_destroyed skip_spy_recovery dont_replace_excavator skip_probe_detected skip_attack_messages
        )) {
        if (exists $args->{$skip}) {
            if ($args->{$skip} != 0 and $args->{$skip} != 1) {
                confess [1009, "$skip must be a 1 or a 0", $skip];
            }
            $empire->$skip($args->{$skip});
        }
    }

    if (exists $args->{skype}) {
        Lacuna::Verify->new(content=>\$args->{skype}, throws=>[1005,'Skype must be no longer than 100 characters, and cannot contain special characters or profanity.', 'skype'])
            ->length_lt(101)
            ->no_restricted_chars
            ->no_profanity
            ->no_bad_words;
        $empire->skype($args->{skype});
    }
    if (exists $args->{email} && $args->{email} ne '') {
        Lacuna::Verify->new(content=>\$args->{email}, throws=>[1005,'The email address specified does not look valid.', 'email'])
            ->is_email if ($args->{email});
        if (Lacuna->db->resultset('Empire')->search({email=>$args->{email}, id=>{ '!=' => $empire->id}})->count > 0) {
            confess [1005, 'That email address is already in use by another empire.', 'email'];
        }
        $empire->email($args->{email});
    }
    $empire->update;    

    # medals
    if (exists $args->{public_medals}) {
        unless (ref $args->{public_medals} eq  'ARRAY') {
            confess [1009, 'Medals list needs to be an array reference.', 'public_medals'];
        }    
        my $medals = $empire->medals;
        while (my $medal = $medals->next) {
            if ($medal->id ~~ $args->{public_medals}) {
                $medal->public(1);
                $medal->update;
            }
            else {
                $medal->public(0);
                $medal->update;
            }
        }
    }
    
    return $self->get_own_profile($empire);
}

# Set your own empires status message
#
sub set_status_message {
    my ($self, $args) = @_;
    
    confess [1019, 'You must call using named arguments.'] if ref($args) ne "HASH";
        
    my $session_id  = $args->{session_id};
    my $message     = $args->{message};            
            
    Lacuna::Verify->new(content=>\$message, throws=>[1005,'Status message invalid.', 'status_message'])
        ->length_lt(101)
        ->not_empty
        ->no_restricted_chars
        ->no_profanity
        ->no_bad_words;
    my $empire = $self->get_empire_by_session($session_id);
    $empire->status_message($message);
    $empire->update;
    return $self->format_status($empire);
}

# View the public profile of any empire
#
sub get_public_profile {
    my ($self, $args) = @_;

    confess [1019, 'You must call using named arguments.'] if ref($args) ne "HASH";

    my $session_id = $args->{session_id};
    my $empire_id = $args->{empire_id};

    my $viewer_empire = $self->get_empire_by_session($session_id);
    my $viewed_empire = Lacuna->db->resultset('Empire')->find($empire_id);
    unless (defined $viewed_empire) {
        confess [1002, 'The empire you wish to view does not exist.', $empire_id];
    }
    my $medals = $viewed_empire->medals->search( { public => 1 } );
    my $public_medals;
    while (my $medal = $medals->next) {
        my $row = {
            id      => $medal->id,
            image   => $medal->image,
            name    => $medal->name,
            date    => $medal->format_datestamp,
            times_earned => $medal->times_earned,
        };
        push @$public_medals, $row;
    }
    my %out = (
        id              => $viewed_empire->id,
        name            => $viewed_empire->name,
        description     => $viewed_empire->description || '',,
        status_message  => $viewed_empire->status_message || '',,
        species         => $viewed_empire->species_name,
        date_founded    => format_date($viewed_empire->date_created),
        last_login      => format_date($viewed_empire->last_login),
        city            => $viewed_empire->city || '',
        country         => $viewed_empire->country || '',
        skype           => $viewed_empire->skype  || '',,
        player_name     => $viewed_empire->player_name || '',,
        colony_count    => $viewed_empire->planets->count,
        medals          => $public_medals,
    );
    if ($viewed_empire->alliance_id) {
        my $alliance = $viewed_empire->alliance;
        $out{alliance} = {
            id      => $alliance->id,
            name    => $alliance->name,
        };
    }
    my @colonies;
    my $probes = Lacuna->db->resultset('Probes')->search_any({empire_id => $viewer_empire->id});
    my $planets = $viewed_empire->planets->search(undef,{order_by => 'name'});
    while (my $colony = $planets->next) {
        if ($colony->id == $viewed_empire->home_planet_id || $probes->search({star_id=>$colony->star_id})->count) {
            push @colonies, $colony->get_status;
        }
    }
    $out{known_colonies} = \@colonies;

    return { public_profile => \%out, status => $self->format_status($viewer_empire) };
}

# Apply a boost to one aspect of the Empire
#
sub set_boost {
    my ($self, $args) = @_;

    confess [1019, 'You must call using named arguments.'] if ref($args) ne "HASH";
    
    my $session_id  = $args->{session_id};
    my $type        = $args->{type}."_boost";

    confess [1002, 'Unknown boost type.'] if $type !~ m/ore|water|energy|food|happiness|storage|building|ship_build|ship_speed/;

    my $empire = $self->get_empire_by_session($session_id);
    if ($empire->essentia < 5) {
        confess [1011, 'Not enough essentia.'];
    }
    $empire->spend_essentia({
        amount  => 5, 
        reason  => $type.' boost',
    });
    my $start = DateTime->now;
    $start = $empire->$type if ($empire->$type > $start);
    $start->add(days=>7);
    $empire->planets->update({needs_recalc=>1, boost_enabled=>1});
    $empire->$type($start);
    $empire->update;
    return $self->get_boosts($args);
}

# View the current empire's boosts
#
sub get_boosts {
    my ($self, $args) = @_;
    
    confess [1019, 'You must call using named arguments.'] if ref($args) ne "HASH";
        
    my $session_id = $args->{session_id};
    my $empire = $self->get_empire_by_session($session_id);
    return {
        status  => $self->format_status($empire),
        boosts  => {
            food        => format_date($empire->food_boost),
            happiness   => format_date($empire->happiness_boost),
            water       => format_date($empire->water_boost),
            ore         => format_date($empire->ore_boost),
            energy      => format_date($empire->energy_boost),
            storage     => format_date($empire->storage_boost),
            building    => format_date($empire->building_boost),
            ship_build  => format_date($empire->ship_build_boost),
            ship_speed  => format_date($empire->ship_speed),
        }
    };
}

# Start the countdown for the empires destruction
#
sub enable_self_destruct {
    my ($self, $args) = @_;
    
    confess [1019, 'You must call using named arguments.'] if ref($args) ne "HASH";

    my $session_id = $args->{session_id};
    my $empire = $self->get_empire_by_session($session_id);
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot enable or disable self destruct.'];
    }
    $empire->enable_self_destruct;
    return { status => $self->format_status($empire) };
}

# Stop the destruction count-down. Phew!
#
sub disable_self_destruct {
    my ($self, $args) = @_;

    confess [1019, 'You must call using named arguments.'] if ref($args) ne "HASH";

    my $session_id = $args->{session_id};
    my $empire = $self->get_empire_by_session($session_id);
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot enable or disable self destruct.'];
    }
    $empire->disable_self_destruct;
    return { status => $self->format_status($empire) };
}

# Increase your empires Essentia by using a code
#
sub redeem_essentia_code {
    my ($self, $args) = @_;

    confess [1019, 'You must call using named arguments.'] if ref($args) ne "HASH";

    my $session_id = $args->{session_id};
    my $code        = $args->{code};

    my $empire = $self->get_empire_by_session($session_id);
    $empire->redeem_essentia_code($code);
    return { status => $self->format_status($empire) };
}

# Get a URL that you can use to invite a friend to the game
#
sub get_invite_friend_url {
    my ($self, $args) = @_;

    confess [1019, 'You must call using named arguments.'] if ref($args) ne "HASH";

    my $session_id = $args->{session_id};
    my $empire = $self->get_empire_by_session($session_id);
    return {
        referral_url    => $empire->get_invite_friend_url,
        status          => $self->format_status($empire),
    };
}

# Get the system to send an email to a friend, inviting them to join the game
#
sub invite_friend {
    my ($self, $args) = @_;

    confess [1019, 'You must call using named arguments.'] if ref($args) ne "HASH";

    my $session_id      = $args->{session_id};
    my $addresses       = $args->{email};
    my $custom_message  = $args->{custom_message};

    my $empire = $self->get_empire_by_session($session_id);
    unless ($empire->email) {
        confess [1010, 'You cannot invite friends because you have not set up your email address in your profile.'];
    }
    my @sent;
    my @not_sent;
    my $csv = Text::CSV_XS->new({allow_whitespace => 1, blank_is_undef => 1, empty_is_undef => 1});
    if ($csv->parse($addresses)) {
        foreach my $email ($csv->fields) {
            eval{$empire->invite_friend($email, $custom_message)};
            my $reason = $@;
            if ($reason) {
                push @not_sent, {
                    address => $email,
                    reason  => $reason,
                };
            }
            else {
                push @sent, $email;
            }
        }
    }
    else {
        confess [1009, 'Could not read the address(es) entered. Perhaps you formatted something incorrectly?', $addresses];
    }
    return { status => $self->format_status($empire), sent => \@sent, not_sent => \@not_sent };
}

# Check that the species configuration is valid
#
sub vet_species {
    my ($self, $args) = @_;

    $args->{name} =~ s{^\s+(.*)\s+$}{$1}xms; # remove leading/trailing white space
    Lacuna::Verify->new(content => \$args->{species_name}, throws=>[1000,'Species name is not available.', 'name'])
        ->length_lt(31)
        ->length_gt(2)
        ->not_empty
        ->no_restricted_chars
        ->no_profanity
        ->no_bad_words;
    Lacuna::Verify->new(content => \$args->{species_description}, throws=>[1005,'Description is invalid.', 'description'])
        ->length_lt(1025)
        ->no_restricted_chars
        ->no_profanity
        ->no_bad_words;

    unless ($args->{species_min_orbit} >= 1 
        && $args->{species_min_orbit} <= 7 ) {
        confess [1009, 'Minimum orbit must be between 1 and 7 and less than or equal to maximum orbit.','species_min_orbit'];
    }
    unless ($args->{species_max_orbit} >= 1 
        && $args->{species_max_orbit} <= 7 
        && $args->{species_max_orbit} >= $args->{species_min_orbit}) {
        confess [1009, 'Maximum orbit must be between 1 and 7 and greater than or equal to minimum orbit.','species_max_orbit'];
    }
    my $points = $args->{species_max_orbit} - $args->{species_min_orbit} + 1;
    foreach my $attr (qw(manufacturing deception research management farming mining science environmental political trade growth)) {
        my $val = int($args->{"species_$attr"});
        if ($val < 1) {
            confess [1008, 'Too little to the species_'.$attr.' affinity.', "species_$attr"];
        }
        if ($val > 7) {
            confess [1007, 'Too much to the species_'.$attr.' affinity.', "species_$attr"];
        }
        $points += $val;
    }
    if ($points > 45) {
        confess [1007, 'You spent too many points.'];
    }
    elsif ($points < 45) {
        confess [1008, 'You did not spend all of your points.'];
    }
}



sub redefine_species_limits {
    my ($self, $args) = @_;

    confess [1019, 'You must call using named arguments.'] if ref($args) ne "HASH";

    my $session_id      = $args->{session_id};

    my $empire = $self->get_empire_by_session($session_id);
    my $out = $empire->determine_species_limits($empire);
    $out->{status} = $self->format_status($empire);
    return $out;
}



sub redefine_species {
    my ($self, $args) = @_;

    confess [1019, 'You must call using named arguments.'] if ref($args) ne "HASH";

    my $session_id      = $args->{session_id};
    
    my $empire = $self->get_empire_by_session($session_id);

    unless ($empire->essentia >= 100) {
        confess [1011, 'You need at least 100 essentia to redefine your species.'];
    }

    $self->vet_species($args);

    my $limits = $empire->determine_species_limits($empire);
    unless ($limits->{can}) {
        confess [1010, $limits->{reason}];
    }
    if ($args->{species_min_orbit} > $limits->{species_min_orbit}) {
        confess [1009, 'Your minimum orbit is '.$limits->{species_min_orbit}.'.'];
    }
    if ($args->{species_growth} < $limits->{species_min_growth}) {
        confess [1009, 'Your minimum growth affinity is '.$limits->{species_in_growth}.'.'];
    }
    
    $empire->spend_essentia({
        amount  => 100, 
        reason  => 'redefine species',
    });
    confess [9999, 'not yet implemented. TODO'];

    $empire->update_species($args);
    $empire->update;
    $empire->planets->update({needs_recalc=>1});
    
    return {
        status  => $self->format_status($empire),
    };
}


sub get_species_stats {
    my ($self, $args) = @_;

    confess [1019, 'You must call using named arguments.'] if ref($args) ne "HASH";

    my $session_id      = $args->{session_id};

    my $empire = $self->get_empire_by_session($session_id);
    return {
        species => $empire->get_species_stats,
        status  => $self->format_status($empire),
    };
}


sub get_species_templates {
    return [
        {
            species_name                    => 'Average',
            species_description             => 'A race of average intellect, and weak constitution.',
            species_min_orbit               => 3,
            species_max_orbit               => 3,
            species_manufacturing  => 4,
            species_deception      => 4,
            species_research       => 4,
            species_management     => 4,
            species_farming        => 4,
            species_mining         => 4,
            species_science        => 4,
            species_environmental  => 4,
            species_political      => 4,
            species_trade          => 4,
            species_growth         => 4,
        },
        {
            species_name                    => 'Resiliant',
            species_description             => 'Resiliant, somewhat docile, but very quick learners and above average at producing any resource.',
            species_min_orbit               => 2,
            species_max_orbit               => 5,
            species_manufacturing  => 3,
            species_deception      => 3,
            species_research       => 3,
            species_management     => 5,
            species_farming        => 5,
            species_mining         => 5,
            species_science        => 5,
            species_environmental  => 5,
            species_political      => 2,
            species_trade          => 2,
            species_growth         => 3,
        },
        {
            species_name                    => 'Builder',
            species_description             => 'Adept at building a colony to maximum levels quickly.',
            species_min_orbit               => 4,
            species_max_orbit               => 4,
            species_manufacturing  => 4,
            species_deception      => 2,
            species_research       => 6,
            species_management     => 6,
            species_farming        => 4,
            species_mining         => 4,
            species_science        => 4,
            species_environmental  => 4,
            species_political      => 2,
            species_trade          => 2,
            species_growth         => 6,
        },
        {
            species_name                    => 'Producer',
            species_description             => 'No resource is a struggle for this species.',
            species_min_orbit               => 2,
            species_max_orbit               => 5,
            species_manufacturing  => 5,
            species_deception      => 2,
            species_research       => 2,
            species_management     => 2,
            species_farming        => 6,
            species_mining         => 6,
            species_science        => 6,
            species_environmental  => 6,
            species_political      => 2,
            species_trade          => 2,
            species_growth         => 2,
        },
        {
            species_name                    => 'Warmonger',
            species_description             => 'Adept at ship building and espionage, they are bent on domination.',
            species_min_orbit               => 4,
            species_max_orbit               => 5,
            species_manufacturing  => 4,
            species_deception      => 7,
            species_research       => 2,
            species_management     => 4,
            species_farming        => 2,
            species_mining         => 2,
            species_science        => 7,
            species_environmental  => 2,
            species_political      => 7,
            species_trade          => 1,
            species_growth         => 5,
        },
        {
            species_name                    => 'Viral',
            species_description             => 'Proficient at growing at a most expedient pace, like a virus.',
            species_min_orbit               => 1,
            species_max_orbit               => 7,
            species_manufacturing  => 1,
            species_deception      => 4,
            species_research       => 7,
            species_management     => 7,
            species_farming        => 1,
            species_mining         => 1,
            species_science        => 1,
            species_environmental  => 1,
            species_political      => 7,
            species_trade          => 1,
            species_growth         => 7,
        },
        {
            species_name                    => 'Trade',
            species_description             => 'Masters of commerce and ship building.',
            species_min_orbit               => 2,
            species_max_orbit               => 3,
            species_manufacturing  => 5,
            species_deception      => 4,
            species_research       => 7,
            species_management     => 7,
            species_farming        => 1,
            species_mining         => 1,
            species_science        => 7,
            species_environmental  => 1,
            species_political      => 1,
            species_trade          => 7,
            species_growth         => 2,
        },
    ]
}

__PACKAGE__->register_rpc_method_names(
    { name => "create", options => { with_plack_request => 1 } },


    qw(
        is_name_available
        find_empire
    ),
    { name => "login", options => { with_plack_request => 1 } },
    { name => "benchmark", options => { with_plack_request => 1 } },
    { name => "reset_password", options => { with_plack_request => 1 } },



qw(redefine_species redefine_species_limits get_invite_friend_url get_species_templates get_species_stats send_password_reset_message invite_friend redeem_essentia_code enable_self_destruct disable_self_destruct change_password set_status_message get_own_profile edit_profile get_public_profile logout get_full_status get_status set_boost get_boosts),
);


no Moose;
__PACKAGE__->meta->make_immutable;

