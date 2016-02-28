package Lacuna::RPC::Empire;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC';
use Lacuna::Util qw(format_date randint real_ip_address);
use DateTime;
use String::Random qw(random_string);
use UUID::Tiny ':std';
use Time::HiRes;
use Text::CSV_XS;
use Firebase::Auth;
use Gravatar::URL;
use List::Util qw(none);
use PerlX::Maybe qw(provided);
use Log::Any qw($log);
use Data::Dumper;

# logging features are new in this level.
use JSON::RPC::Dispatcher 0.0508;

# Add status to the return value
# (currently it always returns status, we can change this to optionally send this
# back or not later)
sub append_status {
    my ($self, $session, $out, $args) = @_;

    # First, only send out once a minute.
    my $cache_empire = Lacuna->cache->get('empire_status_rpc', $session->empire->id);
    if (not $cache_empire or $args->{send_status}) {
        $out->{status} = $self->format_status($session);
#        Lacuna->cache->set('empire_status_rpc', $session->empire->id,  1, 1 * 60);
    }
    return $out;
}


# Is the empire name available?
# (it has to be valid and unique)
#
sub is_name_available {
    my ($self, %args) = @_;

    $self->is_name_valid($args{name});
    $self->is_name_unique($args{name});
    return { is_name_available => 1 }; 
}

# Find empires based on their name
#
sub find {
    my ($self, %args) = @_;

    my $session_id  = $args{session_id};
    my $name        = $args{name};

    if (length($name) < 3) {
        confess [1009, 'Empire name too short. Your search must be at least 3 characters.'];
    }
    my $session	= $self->get_session({session_id => $session_id});
    my $empire  = $session->current_empire;

    my $empires = Lacuna->db->resultset('Empire')->search({name => {'like' => $name.'%'}}, {rows=>100});
    my @list_of_empires;
    my $limit = 100;
    while (my $empire = $empires->next) {
        push @list_of_empires, {
            id      => $empire->id,
            name    => $empire->name,
        };
        $limit--;
        last unless $limit;
    }
    my $out = { empires => \@list_of_empires };
    return $self->append_status($session, $out, \%args);
}

# Is an empire name valid?
#
sub is_name_valid {
    my ($self, $name) = @_;

    Lacuna::Verify->new(content=>\$name, throws=>[1000,'Empire name is invalid.', 'name'])
        ->length_lt(31)
        ->length_gt(2)
        ->not_empty
        ->no_padding
        ->no_restricted_chars
        ->no_match(qr/^#/)
        ->no_profanity;
    return 1;
}

# Is it unique
sub is_name_unique {
    my ($self, $name) = @_;

    if (Lacuna->db->resultset('Empire')->search({name=>$name})->count) {
        confess [1000, 'Empire name is in use by another player.', 'name'];
    }
    return 1;
}

sub logout {
    my ($self, %args) = @_;

    my $session_id = $args{session_id};
    
    $self->get_session($session_id)->end;
    return { logout => 1 };
}


sub login {
    my ($self, $plack_request, %args) = @_;

    my $name        = $args{name};
    my $password    = $args{password};
    my $api_key     = $args{api_key};
    my $browser     = $args{browser};

    unless ($api_key) {
        confess [1002, 'You need an API Key.'];
    }
    my $empire;
    if ($name =~ /^#(-?\d+)$/) {
        $empire = Lacuna->db->resultset('Empire')->find({id=>$1});
    }
    else {
        $empire = Lacuna->db->resultset('Empire')->find({name=>$name});
    }
    unless (defined $empire) {
         confess [1002, 'Empire does not exist.', $name];
    }

    my %session_params = (
        api_key => $api_key,
        request => $plack_request,
        browser => $browser,
    );

    if ($empire->is_password_valid($password)) {
        if ($empire->stage eq 'new') {
            confess [1100, "Your empire has not been completely created. You must complete it in order to play the game.", { empire_id => $empire->id } ];
        }
    }
    elsif ($password ne '' && $empire->sitter_password eq $password) {
        $session_params{is_sitter} = 1;
    }
    else {
        my $ip = real_ip_address($plack_request);

        # might be a mistake, might be an out of date sitter, might be
        # a hacking attempt, let the user know.
        unless (Lacuna->cache->get('invalid_login_attempt_' . $ip, $empire->id)) {
            Lacuna->cache->set('invalid_login_attempt_' . $ip, $empire->id, 1, 12 * 60 * 60);
            $empire->send_predefined_message(
                filename    => 'invalid_login_attempt.txt',
                params      => [ $ip ],
                from        => $empire->lacuna_expanse_corp,
                tags        => [ 'Alert' ],
            );
        }

        confess [1004, 'Password incorrect (' . $ip . ')', $password];
    }

    my $config = Lacuna->config;
    my $throttle = $config->get('rpc_throttle') || 30;
    if ($empire->rpc_rate > $throttle) {
        Lacuna->cache->increment('rpc_limit_'.format_date(undef,'%d'), $empire->id, 1, 60 * 60 * 30);
        confess [1010, 'Slow down, '.$empire->name.'! No more than '.$throttle.' requests per minute.'];
    }
    my $max = $config->get('rpc_limit') || 2500;
    if ($empire->rpc_count > $max) {
        confess [1010, $empire->name.' has already made the maximum number of requests ('.$max.') you can make for one day.'];
    }
    my $firebase_config = $config->get('firebase');
    if ($firebase_config) {
        my $auth_code = Firebase::Auth->new( 
            secret  => $firebase_config->{auth}{secret}, 
            data    => {
                uid         => $empire->id,
                isModerator => $empire->chat_admin  ? \1 : \0,
                isStaff     => $empire->is_admin    ? \1 : \0,
            }
        )->create_token;
    }

    my $session = $empire->start_session(\%session_params);

    my $out = { session_id  => $session->id };
    return $self->append_status($session, $out, \%args);
}


sub benchmark {
    my ($self, $plack_request, %args) = @_;

    my $name        = $args{name};
    my $password    = $args{password};
    my $api_key     = $args{api_key};

    unless ($api_key) {
        confess [1002, 'You need an API Key.'];
    }

    my %out;
    my $t = [Time::HiRes::gettimeofday];
    my $empire = Lacuna->db->resultset('Empire')->search({name=>$name})->next;
    $out{empire} = Time::HiRes::tv_interval($t);

    $t = [Time::HiRes::gettimeofday];
    unless (defined $empire) {
         confess [1002, 'Empire does not exist.', $name];
    }
    if ($empire->stage eq 'new') {
        confess [1010, "You can't log in to an empire that has not been founded."];
    }
    unless ($empire->is_password_valid($password)) {
        confess [1004, 'Password incorrect.', $password];            
    }
    $out{validation} = Time::HiRes::tv_interval($t);

    $t = [Time::HiRes::gettimeofday];
    my $session = $empire->start_session({ api_key => $api_key, request => $plack_request });
    $out{session} = Time::HiRes::tv_interval($t);

    $t = [Time::HiRes::gettimeofday];
    my $home = $empire->home_planet;
    $out{home} = Time::HiRes::tv_interval($t);
    
    $t = [Time::HiRes::gettimeofday];
    $home->tick;
    $out{tick} = Time::HiRes::tv_interval($t);

    $t = [Time::HiRes::gettimeofday];
    $home->command;
    $out{pcc} = Time::HiRes::tv_interval($t);
 
    $t = [Time::HiRes::gettimeofday];
    $self->format_status($session, $home);
    $out{status} = Time::HiRes::tv_interval($t);
 
    return \%out;
}


# Each 'fetch' of a captcha will recover the most recent captcha from the database.
# it will also trigger a job to create a new captcha (for the next person to make
# a request).
#

sub fetch_captcha {
    my ($self, $plack_request) = @_;

    my $ip = $plack_request->address;
    my ($captcha) = Lacuna->db->resultset('Captcha')->search(undef, { rows => 1, order_by => { -desc => 'id'} });

    if (not defined $captcha) {
        # then we have not (yet) created any captchas. Let's make a fake one
        # but not put it in the database
        $captcha = Lacuna->db->resultset('Captcha')->new({
            riddle      => 'Answer 1',
            solution    => 1,
            guid        => 'dummy',
        });
    }

    Lacuna->cache->set('create_empire_captcha', $ip, { guid => $captcha->guid, solution => $captcha->solution }, 60 * 15 );

    # Now trigger a new captcha generation

    my $job = Lacuna->queue->publish('reboot-captcha');

    return {
        guid    => $captcha->guid,
        url     => $captcha->uri,
    };
}

sub change_password {
    my ($self, %args) = @_;

    my $session_id  = $args{session_id};
    my $password1   = $args{password1};
    my $password2   = $args{password2};

    Lacuna::Verify->new(content=>\$password1, throws=>[1001,'Invalid password.', $password1])
        ->length_gt(5)
        ->eq($password2);

    my $session  = $self->get_session({session_id => $session_id});
    my $empire   = $session->current_empire;
    if ($empire->has_current_session && $empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot modify the main args password.'];
    }
    
    $empire->password($empire->encrypt_password($password1));
    $empire->update;

    my $out = { change_password => 1 };
    return $self->append_status($session, $out, \%args);
}


sub send_password_reset_message {
    my ($self, %args) = @_;

    my $empire;
    my $empires = Lacuna->db->resultset('Empire');
    if (exists $args{empire_id} && $args{empire_id} ne '') {
        $empire = $empires->find($args{empire_id});
    }
    elsif (exists $args{empire_name}) {
        $empire = $empires->search({ name => $args{empire_name} })->first;
    }
    elsif (exists $args{email}) {
        $empire = $empires->search({ email => $args{email} })->first;
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


sub reset_password {
    my ($self, $plack_request, %args) = @_;

    my $key         = $args{reset_key};
    my $password1   = $args{password1};
    my $password2   = $args{password2};
    my $api_key     = $args{api_key};

    unless ($api_key) {
        confess [1002, 'You need an API Key.'];
    }
    # verify
    unless (defined $key && $key ne '') {
        confess [1002, 'You need a key to reset a password.'];
    }
    my $empire = Lacuna->db->resultset('Empire')->search({password_recovery_key => $key})->first;
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
    my $session = $empire->start_session({ api_key => $api_key, request => $plack_request });

    my $out = { session_id  => $session->id };
    return $self->append_status($session, $out, \%args);

}

sub create {
    my ($self, $plack_request, %args) = @_;
    my %params = (
        status_message      => 'Making Lacuna a better Expanse.',
        sitter_password     => random_string('CC.c!ccn'),
    );

    # check facebook    
    my $has_facebook = (exists $args{facebook_uid} && $args{facebook_uid} =~ m/^\d+$/ && exists $args{facebook_token} && length($args{facebook_token}) > 60);
    if ($has_facebook) {
        $params{facebook_uid}   = $args{facebook_uid};
        $params{facebook_token} = $args{facebook_token};
    }

    # verify captcha
    unless ($has_facebook) {
        $self->validate_captcha($plack_request, \%args);
    }

    # verify password
    if (exists $args{password} || !$has_facebook) {
        Lacuna::Verify->new(content=>\$args{password}, throws=>[1001,'Invalid password. It must be at least 6 characters and both passwords must match.', 'password'])
            ->length_gt(5)
            ->eq($args{password1});
        $params{password} = Lacuna::DB::Result::Empire->encrypt_password($args{password});
    }
    
    # verify username
    eval { $self->is_name_unique($args{name}) };
    if ($@) { # maybe they're trying to finish an incomplete empire
        my $empire = Lacuna->db->resultset('Empire')->search({name=>$args{name}})->next;
        if (defined $empire) {
            if ($empire->stage eq 'new') {
                if ($empire->is_password_valid($args{password})) {
                    confess [1100, "Your empire has not been completely created. You must complete it in order to play the game.", { empire_id => $empire->id } ];
                }
                else {
                    confess [1101, "Your empire has not been completed created, but you have also entered the wrong password."];
                }
            }
            else {
                confess [1000, 'Empire name is in use by another player.', 'name'];
            }
        }
        else {
            confess [1002, 'Empire has gone away.'];
        }
    }    
    $self->is_name_valid($args{name});
    $params{name} = $args{name};

    # verify email
    if (exists $args{email} && $args{email} ne '') {
        Lacuna::Verify->new(content=>\$args{email}, throws=>[1005,'The email address specified does not look valid.', 'email'])
            ->is_email;
        if (Lacuna->db->resultset('Empire')->search({email=>$args{email}})->count > 0) {
            confess [1005, 'That email address is already in use by another empire.', 'email'];
        }
        $params{email} = $args{email};
    }

    # create args
    my $empire = Lacuna->db->resultset('Empire')->new(\%params)->insert;
    Lacuna->cache->increment('empires_created', format_date(undef,'%F'), 1, 60 * 60 * 26);

    # handle invitation
    $empire->attach_invite_code($args{invite_code});
    
    return { empire_id => $empire->id };
}

sub validate_captcha {
    my ($self, $plack_request, $args) = @_;

    my $guid        = $args->{captcha_guid};
    my $solution    = $args->{captcha_solution};

    my $ip = $plack_request->address;
    if (defined $guid && defined $solution) {                                               # offered a solution
        my $captcha = Lacuna->cache->get_and_deserialize('create_empire_captcha', $ip);
        if (ref $captcha eq 'HASH') {                                                       # a captcha has been set
            if ($captcha->{guid} eq $guid) {                                                # the guid is the one set
                if ($captcha->{solution} eq $solution) {                                    # the solution is correct
                    return 1;
                }
            }
        }
    }
    confess [1014, 'Captcha not valid.', $self->fetch_captcha($plack_request)];
}

sub found {
    my ($self, $plack_request, %args) = @_;

    my $empire_id   = $args{empire_id};
    my $api_key     = $args{api_key};

    unless ($api_key) {
        confess [1002, 'You need an API Key.'];
    }
    if ($empire_id eq '') {
        confess [1002, "You must specify an empire id."];
    }
    my $empire = Lacuna->db->resultset('Empire')->find($empire_id);
    unless (defined $empire) {
        confess [1002, "Invalid empire.", $empire_id];
    }
    unless ($empire->stage eq 'new') {
        confess [1010, "This empire cannot be founded again.", $empire_id];
    }

    my $welcome = $empire->found;
    my $session = $empire->start_session({ api_key => $api_key, request => $plack_request });
    my $out = {
        session_id          => $session->id,
        welcome_message_id  => $welcome->id,
    };

    return $self->append_status($session, $out, \%args);
}

# Get the current empire status
#
sub get_status {
    my ($self, %args) = @_;

    my $session_id = $args{session_id};

    my $session  = $self->get_session({session_id => $session_id});

    return $self->append_status($session, {}, \%args);
}



sub get_own_profile {
    my ($self, %args) = @_;

    my $session_id = $args{session_id};

    my $session  = $self->get_session({session_id => $session_id});
    my $empire   = $session->current_empire;
    if ($empire->has_current_session && $empire->current_session->is_sitter) {
  
        confess [1015, 'Sitters cannot modify preferences.'];
    }
    my $medals = $empire->medals;
    my %my_medals;
    while (my $medal = $medals->next) {
        $my_medals{$medal->id} = {
            name    => $medal->name,
            image   => $medal->image,
            date    => $medal->format_datestamp,
            public  => $medal->public,
            times_earned => $medal->times_earned,
        };
    }
    my $out = {
        profile => {
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
            medals                      => \%my_medals,
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
            skip_incoming_ships         => $empire->skip_incoming_ships,
        }
    };

    return $self->append_status($session, $out, \%args);
}

sub edit_profile {
    my ($self, %args) = @_;

    my $session_id = $args{session_id};
    my $args    = $args{profile};

    my $session  = $self->get_session({session_id => $session_id});
    my $empire   = $session->current_empire;
    
    # preferences
    if ($empire->has_current_session && $empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot modify preferences.'];
    }
    if (exists $args->{description}) {
        Lacuna::Verify->new(content=>\$args->{description}, throws=>[1005,'Description must be less than 1024 characters and cannot contain special characters or profanity.', 'description'])
            ->length_lt(1025)
            ->no_restricted_chars
            ->no_profanity;  
        $empire->description($args->{description});
        if ($empire->tutorial_stage ne 'turing') {
            Lacuna::Tutorial->new(empire=>$empire)->finish;
        }
    }
    if (exists $args->{notes}) {
        Lacuna::Verify->new(content=>\$args->{notes}, throws=>[1005,'Notes must be less than 1024 characters and cannot contain special characters or profanity.', 'notes'])
            ->length_lt(1025)
            ->no_restricted_chars
            ->no_profanity;  
        $empire->notes($args->{notes});
    }
    if (exists $args->{status_message}) {
        Lacuna::Verify->new(content=>\$args->{status_message}, throws=>[1005,'Status cannot be empty, must be no longer than 100 characters, and cannot contain special characters or profanity.', 'status_message'])
            ->length_lt(101)
            ->not_empty
            ->no_restricted_chars
            ->no_profanity;
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
            ->no_profanity;
        $empire->city($args->{city});
    }
    if (exists $args->{country}) {
        Lacuna::Verify->new(content=>\$args->{country}, throws=>[1005,'Country must be no longer than 100 characters, and cannot contain special characters or profanity.', 'country'])
            ->length_lt(101)
            ->no_restricted_chars
            ->no_profanity;
        $empire->country($args->{country});
    }
    if (exists $args->{player_name}) {
        Lacuna::Verify->new(content=>\$args->{player_name}, throws=>[1005,'Player name must be no longer than 100 characters, and cannot contain special characters or profanity.', 'player_name'])
            ->length_lt(101)
            ->no_restricted_chars
            ->no_profanity;
        $empire->player_name($args->{player_name});
    }
    if (exists $args->{skip_medal_messages}) {
        if ($args->{skip_medal_messages} < 0 || $args->{skip_medal_messages} > 1) {
            confess [1009, 'Skip Medal Messages must be a 1 or a 0.', 'skip_medal_messages']
        }
        $empire->skip_medal_messages($args->{skip_medal_messages});
    }
    if (exists $args->{skip_happiness_warnings}) {
        if ($args->{skip_happiness_warnings} < 0 || $args->{skip_happiness_warnings} > 1) {
            confess [1009, 'Skip Happiness Warnings must be a 1 or a 0.', 'skip_happiness_warnings']
        }
        $empire->skip_happiness_warnings($args->{skip_happiness_warnings});
    }
    if (exists $args->{skip_facebook_wall_posts}) {
        if ($args->{skip_facebook_wall_posts} < 0 || $args->{skip_facebook_wall_posts} > 1) {
            confess [1009, 'Skip Facebook Wall Posts must be a 1 or a 0.', 'skip_facebook_wall_posts']
        }
        $empire->skip_facebook_wall_posts($args->{skip_facebook_wall_posts});
    }
    if (exists $args->{skip_resource_warnings}) {
        if ($args->{skip_resource_warnings} < 0 || $args->{skip_resource_warnings} > 1) {
            confess [1009, 'Skip Resource Warnings must be a 1 or a 0.', 'skip_resource_warnings']
        }
        $empire->skip_resource_warnings($args->{skip_resource_warnings});
    }
    if (exists $args->{skip_pollution_warnings}) {
        if ($args->{skip_pollution_warnings} < 0 || $args->{skip_pollution_warnings} > 1) {
            confess [1009, 'Skip Pollution Warnings must be a 1 or a 0.', 'skip_pollution_warnings']
        }
        $empire->skip_pollution_warnings($args->{skip_pollution_warnings});
    }

    if (exists $args->{skip_found_nothing}) {
        if ($args->{skip_found_nothing} < 0 || $args->{skip_found_nothing} > 1) {
            confess [1009, 'Skip Found Nothing must be a 1 or a 0.', 'skip_found_nothing']
        }
        $empire->skip_found_nothing($args->{skip_found_nothing});
    }
    if (exists $args->{skip_excavator_replace_msg}) {
        if ($args->{skip_excavator_replace_msg} < 0 || $args->{skip_excavator_replace_msg} > 1) {
            confess [1009, 'Skip Excavator Replacement Message must be a 1 or a 0.', 'skip_excavator_replace_msg']
        }
        $empire->skip_excavator_replace_msg($args->{skip_excavator_replace_msg});
    }
    if (exists $args->{skip_excavator_resources}) {
        if ($args->{skip_excavator_resources} < 0 || $args->{skip_excavator_resources} > 1) {
            confess [1009, 'Skip Excavator Resources must be a 1 or a 0.', 'skip_excavator_resources']
        }
        $empire->skip_excavator_resources($args->{skip_excavator_resources});
    }
    if (exists $args->{skip_excavator_glyph}) {
        if ($args->{skip_excavator_glyph} < 0 || $args->{skip_excavator_glyph} > 1) {
            confess [1009, 'Skip Excavator Glyph must be a 1 or a 0.', 'skip_excavator_glyph']
        }
        $empire->skip_excavator_glyph($args->{skip_excavator_glyph});
    }
    if (exists $args->{skip_excavator_plan}) {
        if ($args->{skip_excavator_plan} < 0 || $args->{skip_excavator_plan} > 1) {
            confess [1009, 'Skip Excavator Plan must be a 1 or a 0.', 'skip_excavator_plan']
        }
        $empire->skip_excavator_plan($args->{skip_excavator_plan});
    }
    if (exists $args->{skip_excavator_artifact}) {
        if ($args->{skip_excavator_artifact} < 0 || $args->{skip_excavator_artifact} > 1) {
            confess [1009, 'Skip Excavator Artifact must be a 1 or a 0.', 'skip_excavator_artifact']
        }
        $empire->skip_excavator_artifact($args->{skip_excavator_artifact});
    }
    if (exists $args->{skip_excavator_destroyed}) {
        if ($args->{skip_excavator_destroyed} < 0 || $args->{skip_excavator_destroyed} > 1) {
            confess [1009, 'Skip Excavator Destroyed must be a 1 or a 0.', 'skip_excavator_destroyed']
        }
        $empire->skip_excavator_destroyed($args->{skip_excavator_destroyed});
    }
    if (exists $args->{dont_replace_excavator}) {
        if ($args->{dont_replace_excavator} < 0 || $args->{dont_replace_excavator} > 1) {
            confess [1009, 'Do not replace excavator must be a 1 or a 0.', 'dont_replace_excavator']
        }
        $empire->dont_replace_excavator($args->{dont_replace_excavator});
    }
    if (exists $args->{skip_spy_recovery}) {
        if ($args->{skip_spy_recovery} < 0 || $args->{skip_spy_recovery} > 1) {
            confess [1009, 'Skip Spy Recovery must be a 1 or a 0.', 'skip_spy_recovery']
        }
        $empire->skip_spy_recovery($args->{skip_spy_recovery});
    }
    if (exists $args->{skip_probe_detected}) {
        if ($args->{skip_probe_detected} < 0 || $args->{skip_probe_detected} > 1) {
            confess [1009, 'Skip Probe Detected must be a 1 or a 0.', 'skip_probe_detected']
        }
        $empire->skip_probe_detected($args->{skip_probe_detected});
    }
    if (exists $args->{skip_attack_messages}) {
        if ($args->{skip_attack_messages} < 0 || $args->{skip_attack_messages} > 1) {
            confess [1009, 'Skip Attack Messages must be a 1 or a 0.', 'skip_attack_messages']
        }
        $empire->skip_attack_messages($args->{skip_attack_messages});
    }
    if (exists $args->{skip_incoming_ships}) {
        if ($args->{skip_incoming_ships} != 0 && $args->{skip_incoming_ships} != 1) {
            confess [1009, 'Skip Incoming Ships must be a 1 or a 0.', 'skip_incoming_ships']
        }
        $empire->skip_incoming_ships($args->{skip_incoming_ships});
    }

    if (exists $args->{skype}) {
        Lacuna::Verify->new(content=>\$args->{skype}, throws=>[1005,'Skype must be no longer than 100 characters, and cannot contain special characters or profanity.', 'skype'])
            ->length_lt(101)
            ->no_restricted_chars
            ->no_profanity;
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
    
    return $self->get_profile($empire);
}

sub set_status_message {
    my ($self, %args) = @_;

    my $session_id = $args{session_id};
    my $message    = $args{message};

    Lacuna::Verify->new(content=>\$message, throws=>[1005,'Status message invalid.', 'status_message'])
        ->length_lt(101)
        ->not_empty
        ->no_restricted_chars
        ->no_profanity;
    my $session  = $self->get_session({session_id => $session_id});
    my $empire   = $session->current_empire;
    $empire->status_message($message);
    $empire->update;

    return $self->append_status($session, { set_status_message => 1 }, \%args);
}

sub get_public_profile {
    my ($self, %args) = @_;

    my $session_id = $args{session_id};
    my $empire_id  = $args{empire_id};
    my $session  = $self->get_session({session_id => $session_id});

    my $viewer_empire   = $session->current_empire;
    my $viewed_empire = Lacuna->db->resultset('Empire')->find($empire_id);
    unless (defined $viewed_empire) {
        confess [1002, 'The empire you wish to view does not exist.', $empire_id];
    }
    my $medals = $viewed_empire->medals->search( { public => 1 } );
    my %public_medals;
    while (my $medal = $medals->next) {
        $public_medals{$medal->id} = {
            image   => $medal->image,
            name    => $medal->name,
            date    => $medal->format_datestamp,
            times_earned => $medal->times_earned,
        };
    }
    my $out = {
        id              => $viewed_empire->id,
        name            => $viewed_empire->name,
        description     => $viewed_empire->description,
        status_message  => $viewed_empire->status_message,
        species         => $viewed_empire->species_name,
        date_founded    => format_date($viewed_empire->date_created),
        last_login      => format_date($viewed_empire->last_login),
        city            => $viewed_empire->city,
        country         => $viewed_empire->country,
        skype           => $viewed_empire->skype,
        player_name     => $viewed_empire->player_name,
        colony_count    => $viewed_empire->planets->count,
        medals          => \%public_medals,
    };
    if ($viewed_empire->alliance_id) {
        my $alliance = $viewed_empire->alliance;
        $out->{alliance} = {
            id      => $alliance->id,
            name    => $alliance->name,
        };
    }
    my @colonies;
    my $probes = Lacuna->db->resultset('Probes');

    if ($viewer_empire->alliance_id) {
        $probes = $probes->search_any({ alliance_id => $viewer_empire->alliance_id });
    } else {
        $probes = $probes->search_any({ empire_id => $viewer_empire->id });
    }
    my $planets = $viewed_empire->planets->search(undef,{order_by => 'name'});
    while (my $colony = $planets->next) {
        if ($colony->id == $viewed_empire->home_planet_id) {
            unshift @colonies, $colony->get_status;
            $colonies[0]{homeworld} = 1;
        } elsif ($probes->search({star_id=>$colony->star_id})->count) {
            push @colonies, $colony->get_status;
        }
    }
    $out->{known_colonies} = \@colonies;
    return $self->append_status($session, $out, \%args);
}

sub set_boost {
    my ($self, %args) = @_;

    my $session_id = $args{session_id};
    my $type       = $args{type};
    my $weeks      = $args{weeks} || 1;

    my $session  = $self->get_session({session_id => $session_id});
    my $empire   = $session->current_empire;
    $weeks //= 1;

    confess [1001, "Weeks must be a positive integer"]
        unless $weeks >=0 and int($weeks) == $weeks;

    unless ($empire->essentia >= 5 * $weeks) {
        confess [1011, 'Not enough essentia.'];
    }
    $empire->spend_essentia({
        amount  => 5 * $weeks,
        reason  => $type.' boost',
    });
    my $start = DateTime->now;
    $start = $empire->$type if ($empire->$type > $start);
    $start->add(days=>7*$weeks);
    $empire->planets->update({needs_recalc=>1, boost_enabled=>1});
    $empire->$type($start);
    $empire->update;
    my $out = { $type => format_date($empire->$type) };
    return $self->append_status($session, $out, \%args);
}

sub get_boosts {
    my ($self, %args) = @_;

    my $session_id = $args{session_id};

    my $session  = $self->get_session({session_id => $session_id});
    my $empire   = $session->current_empire;
    my $out = {
        boosts  => {
            food         => format_date($empire->food_boost),
            happiness    => format_date($empire->happiness_boost),
            water        => format_date($empire->water_boost),
            ore          => format_date($empire->ore_boost),
            energy       => format_date($empire->energy_boost),
            storage      => format_date($empire->storage_boost),
            building     => format_date($empire->building_boost),
            spy_training => format_date($empire->spy_training_boost),
        }
    };
    return $self->append_status($session, $out, \%args);
}

sub enable_self_destruct {
    my ($self, %args) = @_;

    my $session_id = $args{session_id};

    my $session  = $self->get_session({session_id => $session_id});
    my $empire   = $session->current_empire;
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot enable or disable self destruct.'];
    }
    $empire->enable_self_destruct;
    my $out = { enable_self_destruct => 1 };
    return $self->append_status($session, $out, \%args);
}

sub disable_self_destruct {
    my ($self, %args) = @_;

    my $session_id = $args{session_id};

    my $session  = $self->get_session({session_id => $session_id});
    my $empire   = $session->current_empire;
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot enable or disable self destruct.'];
    }
    $empire->disable_self_destruct;
    my $out = { disable_self_destruct => 1 };
    return $self->append_status($session, $out, \%args);
}

sub redeem_essentia_code {
    my ($self, %args) = @_;

    my $session_id = $args{session_id};
    my $code       = $args{code};

    my $session  = $self->get_session({session_id => $session_id});
    my $empire   = $session->current_empire;
    my $amount = $empire->redeem_essentia_code($code);

    my $out = { amount => $amount };
    return $self->append_status($session, $out, \%args);
}

sub get_invite_friend_url {
    my ($self, %args) = @_;

    my $session_id  = $args{session_id};

    my $session  = $self->get_session({session_id => $session_id});
    my $empire   = $session->current_empire;
    my $out = { referral_url => $empire->get_invite_friend_url };
    return $self->append_status($session, $out, \%args);
}


sub invite_friend {
    my ($self, %args) = @_;

    my $session_id      = $args{session_id};
    my $addresses       = $args{email};
    my $custom_message  = $args{custom_message};

    my $session  = $self->get_session({session_id => $session_id});
    my $empire   = $session->current_empire;
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
    my $out = { 
        sent        => \@sent,
        not_sent    => \@not_sent,
    };
    return $self->append_status($session, $out, \%args);
}

sub vet_species {
    my ($self, $args) = @_;
    # make sure the name is valid
    $args->{name} =~ s{^\s+(.*)\s+$}{$1}xms; # remove extra white space
    Lacuna::Verify->new(content=>\$args->{name}, throws=>[1000,'Species name not available.', 'name'])
        ->length_lt(31)
        ->length_gt(2)
        ->not_empty
        ->no_restricted_chars
        ->no_profanity;

    # and the description        
    Lacuna::Verify->new(content=>\$args->{description}, throws=>[1005,'Description invalid.', 'description'])
        ->length_lt(1025)
        ->no_restricted_chars
        ->no_profanity;  
    
    # how about orbits
    unless ($args->{min_orbit} >= 1 && $args->{min_orbit} <= 7 && $args->{min_orbit} <= $args->{max_orbit}) {
        confess [1009, 'Minimum orbit must be between 1 and 7 and less than or equal to maximum orbit.','min_orbit'];
    }
    unless ($args->{max_orbit} >= 1 && $args->{max_orbit} <= 7 && $args->{max_orbit} >= $args->{min_orbit}) {
        confess [1009, 'Maximum orbit must be between 1 and 7 and greater than or equal to minimum orbit.','min_orbit'];
    }
 
    # deal with point allocation
    my $points = $args->{max_orbit} - $args->{min_orbit} + 1;
    foreach my $attr (qw(manufacturing_affinity deception_affinity research_affinity management_affinity farming_affinity mining_affinity science_affinity environmental_affinity political_affinity trade_affinity growth_affinity)) {
        $args->{$attr} += 0; # ensure it's a number
        if ($args->{$attr} < 1) {
            confess [1008, 'Too little to the '.$attr.' affinity.', $attr];
        }
        elsif ($args->{$attr} > 7) {
            confess [1007, 'Too much to the '.$attr.' affinity.', $attr];
        }
        $points += $args->{$attr};
    }
    if ($points > 45) {
        confess [1007, 'You spent too many points.'];
    }
    elsif ($points < 45) {
        confess [1008, 'You did not spend all of your points.'];
    }
}

sub get_redefine_species_limits {
    my ($self, %args) = @_;
    
    my $session_id = $args{session_id};

    my $session = $self->get_session({session_id => $session_id});
    my $empire  = $session->current_empire;

    my $out     = $empire->determine_species_limits($empire);
    return $self->append_status($session, $out, \%args);
}

sub redefine_species {
    my ($self, %args) = @_;
    my $session  = $self->get_session( {session_id => $args{session_id} });
    my $empire   = $session->current_empire;

    unless ($empire->essentia >= 100) {
        confess [1011, 'You need at least 100 essentia to redefine your species.'];
    }

    $self->vet_species(\%args);

    my $limits = $empire->determine_species_limits($empire);
    unless ($limits->{can}) {
        confess [1010, $limits->{reason}];
    }
    if ($args{min_orbit} > $limits->{min_orbit}) {
        confess [1009, 'Your minimum orbit is '.$limits->{min_orbit}.'.'];
    }
    if ($args{max_orbit} < $limits->{max_orbit}) {
        confess [1009, 'Your maximum orbit is '.$limits->{max_orbit}.'.'];
    }
    if ($args{growth_affinity} < $limits->{min_growth}) {
        confess [1009, 'Your minimum growth affinity is '.$limits->{min_growth}.'.'];
    }
    
    $empire->spend_essentia({
        amount  => 100, 
        reason  => 'redefine species',
    });
    $empire->update_species(%args);
    $empire->update;
    $empire->planets->update({needs_recalc=>1});
    
    my $out = { redefine_species => 1 };
    return $self->append_status($session, $out, \%args);
}


sub update_species {
    my ($self, %args) = @_;

    $log->debug(Dumper(\%args));
    my $empire_id = $args{empire_id};

    # make sure it's a valid empire
    unless ($empire_id ne '') {
        confess [1002, "You must specify an empire id."];
    }
    my $empire = Lacuna->db->resultset('Empire')->find($empire_id);
    unless (defined $empire) {
        confess [1002, "Not a valid empire.",'empire_id'];
    }

    # deal with an empire in motion
    if ($empire->stage ne 'new') {
        confess [1010, "You can't establish a new species for an empire that's already founded.",'empire_id'];
    }

    $self->vet_species(\%args);
    $empire->update_species(\%args)->update;


    $log->debug(Dumper($empire->{_column_data}));

    return {
        update_species => 1
    };
}

sub get_species_stats {
    my ($self, %args) = @_;

    my $session_id = $args{session_id};
    my $session  = $self->get_session({session_id => $session_id});
    my $empire   = $session->current_empire;
    
    my $out = { species => $empire->get_species_stats };
    return $self->append_status($session, $out, \%args);
}


sub get_species_templates {
    return [
        {
            name                    => 'Average',
            description             => 'A race of average intellect, and weak constitution.',
            min_orbit               => 3,
            max_orbit               => 3,
            manufacturing_affinity  => 4,
            deception_affinity      => 4,
            research_affinity       => 4,
            management_affinity     => 4,
            farming_affinity        => 4,
            mining_affinity         => 4,
            science_affinity        => 4,
            environmental_affinity  => 4,
            political_affinity      => 4,
            trade_affinity          => 4,
            growth_affinity         => 4,
        },
        {
            name                    => 'Resiliant',
            description             => 'Resiliant, somewhat docile, but very quick learners and above average at producing any resource.',
            min_orbit               => 2,
            max_orbit               => 5,
            manufacturing_affinity  => 3,
            deception_affinity      => 3,
            research_affinity       => 3,
            management_affinity     => 5,
            farming_affinity        => 5,
            mining_affinity         => 5,
            science_affinity        => 5,
            environmental_affinity  => 5,
            political_affinity      => 2,
            trade_affinity          => 2,
            growth_affinity         => 3,
        },
        {
            name                    => 'Builder',
            description             => 'Adept at building a colony to maximum levels quickly.',
            min_orbit               => 4,
            max_orbit               => 4,
            manufacturing_affinity  => 4,
            deception_affinity      => 2,
            research_affinity       => 6,
            management_affinity     => 6,
            farming_affinity        => 4,
            mining_affinity         => 4,
            science_affinity        => 4,
            environmental_affinity  => 4,
            political_affinity      => 2,
            trade_affinity          => 2,
            growth_affinity         => 6,
        },
        {
            name                    => 'Producer',
            description             => 'No resource is a struggle for this species.',
            min_orbit               => 2,
            max_orbit               => 5,
            manufacturing_affinity  => 5,
            deception_affinity      => 2,
            research_affinity       => 2,
            management_affinity     => 2,
            farming_affinity        => 6,
            mining_affinity         => 6,
            science_affinity        => 6,
            environmental_affinity  => 6,
            political_affinity      => 2,
            trade_affinity          => 2,
            growth_affinity         => 2,
        },
        {
            name                    => 'Warmonger',
            description             => 'Adept at ship building and espionage, they are bent on domination.',
            min_orbit               => 4,
            max_orbit               => 5,
            manufacturing_affinity  => 4,
            deception_affinity      => 7,
            research_affinity       => 2,
            management_affinity     => 4,
            farming_affinity        => 2,
            mining_affinity         => 2,
            science_affinity        => 7,
            environmental_affinity  => 2,
            political_affinity      => 7,
            trade_affinity          => 1,
            growth_affinity         => 5,
        },
        {
            name                    => 'Viral',
            description             => 'Proficient at growing at a most expedient pace, like a virus.',
            min_orbit               => 1,
            max_orbit               => 7,
            manufacturing_affinity  => 1,
            deception_affinity      => 4,
            research_affinity       => 7,
            management_affinity     => 7,
            farming_affinity        => 1,
            mining_affinity         => 1,
            science_affinity        => 1,
            environmental_affinity  => 1,
            political_affinity      => 7,
            trade_affinity          => 1,
            growth_affinity         => 7,
        },
        {
            name                    => 'Trade',
            description             => 'Masters of commerce and ship building.',
            min_orbit               => 2,
            max_orbit               => 3,
            manufacturing_affinity  => 5,
            deception_affinity      => 4,
            research_affinity       => 7,
            management_affinity     => 7,
            farming_affinity        => 1,
            mining_affinity         => 1,
            science_affinity        => 7,
            environmental_affinity  => 1,
            political_affinity      => 1,
            trade_affinity          => 7,
            growth_affinity         => 2,
        },
    ]
}

sub get_authorized_sitters {
    my ($self, %args) = @_;

    my $session_id = $args{session_id};

    my $session = $self->get_session({session_id => $session_id});
    my $baby = $session->current_empire();

    my $rs = $baby->sitters()->search({},{
       '+select' => [ 'me.expiry' ],
       '+as'     => [ 'expiry' ],
       order_by  => 'sitter.name',
    });

    my $parser = Lacuna->db->storage->datetime_parser;

    my @auths;
    while (my $e = $rs->next) {
        push @auths, {
            id     => $e->id,
            name   => $e->name,
            expiry => format_date($parser->parse_datetime($e->get_column('expiry'))),
        };
    }

    my $out = { sitters => \@auths };
    return $self->append_status($session, $out, \%args);
}

sub authorize_sitters {
    my ($self, %args) = @_;

    my $session_id = $args{session_id};
    my $session  = $self->get_session({session_id => $session_id});
    $session->check_captcha;

    my $baby = $session->current_empire;
    my $baby_id = $session->empire_id;
    my $rs = $baby->sitters;
    my $auths = Lacuna->db->resultset('SitterAuths');

    my @sitters;
    if ($args{allied}) {
        if ($baby->alliance_id) {
            push @sitters, $baby->alliance->members->get_column('id')->all;
        }
    }
    if ($args{alliance}) {
        my $alliance = Lacuna->db->resultset('Alliance')->find({name => $args{alliance}});
        if ($alliance) {
            push @sitters, $alliance->members->all;
        }
    }
    if ($args{alliance_id}) {
        my $alliance = Lacuna->db->resultset('Alliance')->find({id => $args{alliance_id}});
        if ($alliance) {
            push @sitters, $alliance->members->all;
        }
    }
    if ($args{empires} and ref $args{empires} eq 'ARRAY') {
        push @sitters, @{$args{empires}};
    }
    if ($args{revalidate_all}) {
        push @sitters, $rs->get_column('me.sitter_id')->all;
    }
    confess [1009, "No sitters selected"] unless @sitters;

    my @bad_ids;
    for my $sitter (@sitters) {
        my $sit = eval { ref $sitter && $sitter->isa('Lacuna::DB::Result::Empire') } ?
            $sitter :
            Lacuna->db->empire($sitter);
        if ($sit) {
            my $sitter_id = $sit->id;
            next if $sitter_id == $baby_id;

            my $auth = $auths->find({baby_id => $baby_id, sitter_id => $sitter_id});
            $auth  //= $auths->new({baby_id => $baby_id, sitter_id => $sitter_id});
            $auth->reauthorise;
            $auth->update_or_insert;
        }
        else {
            push @bad_ids, $sitter;
        }
    }

    my $rc = $self->get_authorized_sitters($session);
    $rc->{rejected_ids} = \@bad_ids;
    return $rc;
}

sub deauthorize_sitters {
    my ($self, %args) = @_;

    my $session_id = $args{session_id};

    my $session  = $self->get_session({session_id => $session_id});
    my $baby = $session->current_empire;

    my $baby_id = $session->empire_id;

    confess [1009, "The 'empires' option must be an array of empire IDs"]
        unless $args{empires} and ref $args{empires} eq 'ARRAY' and
        none { /\D/ } @{$args{empires}};

    my $dtf = Lacuna->db->storage->datetime_parser;
    my $now = $dtf->format_datetime(DateTime->now);

    # set expiry to immediate
    my $rs = Lacuna->db->resultset('SitterAuths');
    $rs->search({
        baby_id     => $baby_id, 
        sitter_id   => { in => $args{empires} }
    })->update({
        expiry      => $now
    });

    return $self->get_authorized_sitters($session);
}

sub _rewrite_request_for_logging {
    my ($method, $params) = @_;
    if ($method eq 'login') {
        $params = {
            @$params,
            password => 'xxx',
        };
    }
    elsif ($method eq 'change_password') {
        $params = {
            @$params,
            password1 => 'xxx',
            password2 => 'xxx',
        };
    }
    elsif ($method eq 'reset_password') {
        $params = {
            @$params,
            password1 => 'xxx',
            password2 => 'xxx',
        };
    }
    elsif ($method eq 'create') {
        $params = {
            @$params,
            password => 'xxx',
        };
    }
    elsif ($method eq 'edit_profile') {
        $params = {
            @$params,
            provided $params->{sitter_password}, sitter_password => 'xxx',
        }
    }
    return $params;
}

__PACKAGE__->register_rpc_method_names(
    { name => "create", options => { with_plack_request => 1, log_request_as => \&_rewrite_request_for_logging } },
    { name => "fetch_captcha", options => { with_plack_request => 1 } },
    { name => "login", options => { with_plack_request => 1, log_request_as => \&_rewrite_request_for_logging } },
    { name => "benchmark", options => { with_plack_request => 1 } },
    { name => "found", options => { with_plack_request => 1 } },
    { name => "reset_password", options => { with_plack_request => 1, log_request_as => \&_rewrite_request_for_logging } },
    { name => 'change_password', options => { log_request_as => \&_rewrite_request_for_logging } },
    { name => 'edit_profile', options => { log_request_as => \&_rewrite_request_for_logging } },
    qw(
    redefine_species get_redefine_species_limits
    get_invite_friend_url
    get_species_templates update_species get_species_stats
    send_password_reset_message
    invite_friend
    redeem_essentia_code
    enable_self_destruct disable_self_destruct
    set_status_message
    find
    get_profile get_public_profile
    is_name_available
    logout
    get_full_status get_status
    boost get_boosts    
    get_authorized_sitters authorize_sitters deauthorize_sitters
    ),
);


no Moose;
__PACKAGE__->meta->make_immutable;

