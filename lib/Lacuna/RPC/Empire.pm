package Lacuna::RPC::Empire;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC';
use Lacuna::Util qw(format_date randint);
use DateTime;
use String::Random qw(random_string);
use UUID::Tiny;

sub find {
    my ($self, $session_id, $name) = @_;
    unless (length($name) >= 3) {
        confess [1009, 'Empire name too short. Your search must be at least 3 characters.'];
    }
    my $empire = $self->get_empire_by_session($session_id);
    my $empires = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({name => {'like' => $name.'%'}}, {rows=>100});
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
    return { empires => \@list_of_empires, status => $self->format_status($empire) };
}

sub is_name_available {
    my ($self, $name) = @_;
    Lacuna::Verify->new(content=>\$name, throws=>[1000,'Empire name not available.', 'name'])
        ->length_lt(31)
        ->length_gt(2)
        ->not_empty
        ->no_padding
        ->no_restricted_chars
        ->no_profanity
        ->ok( !Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({name=>$name})->count );
    return 1; 
}

sub logout {
    my ($self, $session_id) = @_;
    $self->get_session($session_id)->end;
    return 1;
}

sub login {
    my ($self, $plack_request, $name, $password, $api_key) = @_;
    unless ($api_key) {
        confess [1002, 'You need an API Key.'];
    }
    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({name=>$name})->next;
    unless (defined $empire) {
         confess [1002, 'Empire does not exist.', $name];
    }
    if ($empire->stage eq 'new') {
        confess [1010, "You can't log in to an empire that has not been founded."];
    }
    unless ($empire->is_password_valid($password)) {
        if ($password ne '' && $empire->sitter_password eq $password) {
            return { session_id => $empire->start_session({ api_key => $api_key, request => $plack_request, is_sitter => 1 })->id, status => $self->format_status($empire) };
        }
        else {
            confess [1004, 'Password incorrect.', $password];            
        }
    }
    return { session_id => $empire->start_session({ api_key => $api_key, request => $plack_request })->id, status => $self->format_status($empire) };
}


sub fetch_captcha {
    my ($self, $plack_request) = @_;
    my $ip = $plack_request->address;
    my $captcha = Lacuna->db->resultset('Lacuna::DB::Result::Captcha')->find(randint(1,65664));
    Lacuna->cache->set('create_empire_captcha', $ip, { guid => $captcha->guid, solution => $captcha->solution }, 60 * 15 );
    return {
        guid    => $captcha->guid,
        url     => $captcha->uri,
    };
}

sub change_password {
    my ($self, $session_id, $password, $password1, $password2) = @_;
    Lacuna::Verify->new(content=>\$password1, throws=>[1001,'Invalid password.', $password1])
        ->length_gt(5)
        ->eq($password2);

    my $empire = $self->get_empire_by_session($session_id);
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot modify preferences.'];
    }
    unless ($empire->is_password_valid($password)) { # just in case the person walks away from their device, or the session is somehow hijacked
        confess [1004, 'Current password incorrect.', $password];            
    }
    
    $empire->password($empire->encrypt_password($password1));
    $empire->update;
    return { status => $self->format_status($empire) };
}


sub send_password_reset_message {
    my ($self, %options) = @_;
    my $empire;
    my $empires = Lacuna->db->resultset('Lacuna::DB::Result::Empire');
    if (exists $options{empire_id} && $options{empire_id} ne '') {
        $empire = $empires->find($options{empire_id});
    }
    elsif (exists $options{empire_name}) {
        $empire = $empires->search({ name => $options{empire_name} }, { rows => 1 })->single;
    }
    elsif (exists $options{email}) {
        $empire = $empires->search({ email => $options{email} }, { rows => 1 })->single;
    }
    unless (defined $empire) {
        confess [1002, 'Empire not found.'];
    }
    unless ($empire->email) {
        confess [1002, 'That empire has no email address specified.'];
    }
    $empire->password_recovery_key(create_UUID_as_string(UUID_V4));
    $empire->update;
    
    my $message = "Use the key or the link below to reset the password for %s.\n\nKey: %s\n\n%s#reset_password=%s";
    $empire->send_email(
        'Reset Your Password',
        sprintf($message, $empire->name, $empire->password_recovery_key, Lacuna->config->get('server_url'), $empire->password_recovery_key),
    );
    return { sent => 1 };
}


sub reset_password {
    my ($self, $plack_request, $key, $password1, $password2, $api_key) = @_;
    unless ($api_key) {
        confess [1002, 'You need an API Key.'];
    }
    # verify
    unless (defined $key && $key ne '') {
        confess [1002, 'You need a key to reset a password.'];
    }
    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({password_recovery_key => $key}, { rows=>1 })->single;
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


sub create {
    my ($self, $plack_request, %account) = @_;    
    my %params = (
        status_message      => 'Making Lacuna a better Expanse.',
        sitter_password     => random_string('CC.c!ccn'),
    );

if ($account{captcha_guid}) { # get rid of this IF before we go live
    # verify captcha
    $self->validate_captcha($plack_request, $account{captcha_guid}, $account{captcha_solution});
}

    # check facebook    
    my $has_facebook = (exists $account{facebook_uid} && $account{facebook_uid} =~ m/^\d+$/ && exists $account{facebook_token} && length($account{facebook_token}) > 60);
    if ($has_facebook) {
        $params{facebook_uid}   = $account{facebook_uid};
        $params{facebook_token} = $account{facebook_token};
    }

    # verify password
    if (exists $account{password} || !$has_facebook) {
        Lacuna::Verify->new(content=>\$account{password}, throws=>[1001,'Invalid password. It must be at least 6 characters and both passwords must match.', 'password'])
            ->length_gt(5)
            ->eq($account{password1});
        $params{password} = Lacuna::DB::Result::Empire->encrypt_password($account{password});
    }
    
    # verify email
    if (exists $account{email} && $account{email} ne '') {
        Lacuna::Verify->new(content=>\$account{email}, throws=>[1005,'The email address specified does not look valid.', 'email'])
            ->is_email;
        if (Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({email=>$account{email}})->count > 0) {
            confess [1005, 'That email address is already in use by another empire.', 'email'];
        }
        $params{email} = $account{email};
    }

    # verify username
    $self->is_name_available($account{name});
    $params{name} = $account{name};

    # create account
    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->new(\%params)->insert;
    return $empire->id;
}

sub validate_captcha {
    my ($self, $plack_request, $guid, $solution) = @_;
    my $ip = $plack_request->address;
    if ($guid && $solution) {                                                               # offered a solution
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
    my ($self, $plack_request, $empire_id, $api_key, $invite_code) = @_;
    unless ($api_key) {
        confess [1002, 'You need an API Key.'];
    }
    if ($empire_id eq '') {
        confess [1002, "You must specify an empire id."];
    }
    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($empire_id);
    unless (defined $empire) {
        confess [1002, "Invalid empire.", $empire_id];
    }
    unless ($empire->stage eq 'new') {
        confess [1010, "This empire cannot be founded again.", $empire_id];
    }
    my $welcome = $empire->found(undef, $invite_code);
    return {
        session_id          => $empire->start_session({ api_key => $api_key, request => $plack_request })->id,
        status              => $self->format_status($empire),
        welcome_message_id  => $welcome->id,
    };
}

sub get_status {
    my ($self, $session_id) = @_;
    return $self->format_status($self->get_empire_by_session($session_id));
}

sub view_profile {
    my ($self, $session_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    if ($empire->current_session->is_sitter) {
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
    my %out = (
        description             => $empire->description,
        notes                   => $empire->notes,
        status_message          => $empire->status_message,
        sitter_password         => $empire->sitter_password,
        email                   => $empire->email,
        city                    => $empire->city,
        country                 => $empire->country,
        skype                   => $empire->skype,
        player_name             => $empire->player_name,
        skip_medal_messages     => $empire->skip_medal_messages,
        skip_pollution_warnings => $empire->skip_pollution_warnings,
        skip_resource_warnings  => $empire->skip_resource_warnings,
        skip_happiness_warnings => $empire->skip_happiness_warnings,
        medals                  => \%my_medals,
    );
    return { profile => \%out, status => $self->format_status($empire) };    
}

sub edit_profile {
    my ($self, $session_id, $profile) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    
    # preferences
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot modify preferences.'];
    }
    if (exists $profile->{description}) {
        Lacuna::Verify->new(content=>\$profile->{description}, throws=>[1005,'Description must be less than 1024 characters and cannot contain special characters or profanity.', 'description'])
            ->length_lt(1025)
            ->no_restricted_chars
            ->no_profanity;  
        $empire->description($profile->{description});
        if ($empire->tutorial_stage ne 'turing') {
            Lacuna::Tutorial->new(empire=>$empire)->finish;
        }
    }
    if (exists $profile->{notes}) {
        Lacuna::Verify->new(content=>\$profile->{notes}, throws=>[1005,'Notes must be less than 1024 characters and cannot contain special characters or profanity.', 'notes'])
            ->length_lt(1025)
            ->no_restricted_chars
            ->no_profanity;  
        $empire->notes($profile->{notes});
    }
    if (exists $profile->{status_message}) {
        Lacuna::Verify->new(content=>\$profile->{status_message}, throws=>[1005,'Status cannot be empty, must be no longer than 100 characters, and cannot contain special characters or profanity.', 'status_message'])
            ->length_lt(101)
            ->not_empty
            ->no_restricted_chars
            ->no_profanity;
        $empire->status_message($profile->{status_message});
    }
    if (exists $profile->{sitter_password}) {
        Lacuna::Verify->new(content=>\$profile->{sitter_password}, throws=>[1005,'Sitter password must be between 6 and 30 characters.', 'sitter_password'])
            ->length_lt(31)
            ->length_gt(5);
        $empire->sitter_password($profile->{sitter_password});
    }
    if (exists $profile->{city}) {
        Lacuna::Verify->new(content=>\$profile->{city}, throws=>[1005,'City must be no longer than 100 characters, and cannot contain special characters or profanity.', 'city'])
            ->length_lt(101)
            ->no_restricted_chars
            ->no_profanity;
        $empire->city($profile->{city});
    }
    if (exists $profile->{country}) {
        Lacuna::Verify->new(content=>\$profile->{country}, throws=>[1005,'Country must be no longer than 100 characters, and cannot contain special characters or profanity.', 'country'])
            ->length_lt(101)
            ->no_restricted_chars
            ->no_profanity;
        $empire->country($profile->{country});
    }
    if (exists $profile->{player_name}) {
        Lacuna::Verify->new(content=>\$profile->{player_name}, throws=>[1005,'Player name must be no longer than 100 characters, and cannot contain special characters or profanity.', 'player_name'])
            ->length_lt(101)
            ->no_restricted_chars
            ->no_profanity;
        $empire->player_name($profile->{player_name});
    }
    if (exists $profile->{skip_medal_messages}) {
        if ($profile->{skip_medal_messages} < 0 || $profile->{skip_medal_messages} > 1) {
            confess [1009, 'Skip Medal Messages must be a 1 or a 0.', 'skip_medal_messages']
        }
        $empire->skip_medal_messages($profile->{skip_medal_messages});
    }
    if (exists $profile->{skip_happiness_warnings}) {
        if ($profile->{skip_happiness_warnings} < 0 || $profile->{skip_happiness_warnings} > 1) {
            confess [1009, 'Skip Happiness Warnings must be a 1 or a 0.', 'skip_happiness_warnings']
        }
        $empire->sskip_happiness_warnings($profile->{skip_happiness_warnings});
    }
    if (exists $profile->{skip_resource_warnings}) {
        if ($profile->{skip_resource_warnings} < 0 || $profile->{skip_resource_warnings} > 1) {
            confess [1009, 'Skip Resource Warnings must be a 1 or a 0.', 'skip_resource_warnings']
        }
        $empire->skip_resource_warnings($profile->{skip_resource_warnings});
    }
    if (exists $profile->{skip_pollution_warnings}) {
        if ($profile->{skip_pollution_warnings} < 0 || $profile->{skip_pollution_warnings} > 1) {
            confess [1009, 'Skip Pollution Warnings must be a 1 or a 0.', 'skip_pollution_warnings']
        }
        $empire->skip_pollution_warnings($profile->{skip_pollution_warnings});
    }
    if (exists $profile->{skype}) {
        Lacuna::Verify->new(content=>\$profile->{skype}, throws=>[1005,'Skype must be no longer than 100 characters, and cannot contain special characters or profanity.', 'skype'])
            ->length_lt(101)
            ->no_restricted_chars
            ->no_profanity;
        $empire->skype($profile->{skype});
    }
    if (exists $profile->{email} && $profile->{email} ne '') {
        Lacuna::Verify->new(content=>\$profile->{email}, throws=>[1005,'The email address specified does not look valid.', 'email'])
            ->is_email if ($profile->{email});
        if (Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({email=>$profile->{email}, id=>{ '!=' => $empire->id}})->count > 0) {
            confess [1005, 'That email address is already in use by another empire.', 'email'];
        }
        $empire->email($profile->{email});
    }
    $empire->update;    

    # medals
    if (exists $profile->{public_medals}) {
        unless (ref $profile->{public_medals} eq  'ARRAY') {
            confess [1009, 'Medals list needs to be an array reference.', 'public_medals'];
        }    
        my $medals = $empire->medals;
        while (my $medal = $medals->next) {
            if ($medal->id ~~ $profile->{public_medals}) {
                $medal->public(1);
                $medal->update;
            }
            else {
                $medal->public(0);
                $medal->update;
            }
        }
    }
    
    return $self->view_profile($empire);
}

sub set_status_message {
    my ($self, $session_id, $message) = @_;
    Lacuna::Verify->new(content=>\$message, throws=>[1005,'Status message invalid.', 'status_message'])
        ->length_lt(101)
        ->not_empty
        ->no_restricted_chars
        ->no_profanity;
    my $empire = $self->get_empire_by_session($session_id);
    $empire->status_message($message);
    $empire->update;
    return $self->format_status($empire);
}

sub view_public_profile {
    my ($self, $session_id, $empire_id) = @_;
    my $viewer_empire = $self->get_empire_by_session($session_id);
    my $viewed_empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($empire_id);
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
    my %out = (
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
    );
    my @colonies;
    my $probes = Lacuna->db->resultset('Lacuna::DB::Result::Probes')->search({empire_id => $viewer_empire->id});
    my $planets = $viewed_empire->planets->search(undef,{order_by => 'name'});
    while (my $colony = $planets->next) {
        if ($colony->id == $viewed_empire->home_planet_id || $probes->search({star_id=>$colony->star_id})->count) {
            push @colonies, $colony->get_status;
        }
    }
    $out{known_colonies} = \@colonies;

    return { profile => \%out, status => $self->format_status($viewer_empire) };
}

sub boost_ore {
    my ($self, $session_id) = @_;
    return $self->boost($session_id, 'ore_boost');
}

sub boost_water {
    my ($self, $session_id) = @_;
    return $self->boost($session_id, 'water_boost');
}

sub boost_energy {
    my ($self, $session_id) = @_;
    return $self->boost($session_id, 'energy_boost');
}

sub boost_food {
    my ($self, $session_id) = @_;
    return $self->boost($session_id, 'food_boost');
}

sub boost_happiness {
    my ($self, $session_id) = @_;
    return $self->boost($session_id, 'happiness_boost');
}

sub boost_storage {
    my ($self, $session_id) = @_;
    return $self->boost($session_id, 'storage_boost');
}

sub boost {
    my ($self, $session_id, $type) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    unless ($empire->essentia >= 5) {
        confess [1011, 'Not enough essentia.'];
    }
    $empire->spend_essentia(5, $type.' boost');
    my $start = DateTime->now;
    $start = $empire->$type if ($empire->$type > $start);
    $start->add(days=>7);
    $empire->planets->update({needs_recalc=>1});
    $empire->$type($start);
    $empire->update;
    if ($empire->tutorial_stage ne 'turing') {
        Lacuna::Tutorial->new(empire=>$empire)->finish;
    }
    return {
        status => $self->format_status($empire),
        $type => format_date($empire->$type),
    };
}

sub view_boosts {
    my ($self, $session_id) = @_;
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
        }
    };
}

sub enable_self_destruct {
    my ($self, $session_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot enable or disable self destruct.'];
    }
    $empire->enable_self_destruct;
    return { status => $self->format_status($empire) };
}

sub disable_self_destruct {
    my ($self, $session_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    if ($empire->current_session->is_sitter) {
        confess [1015, 'Sitters cannot enable or disable self destruct.'];
    }
    $empire->disable_self_destruct;
    return { status => $self->format_status($empire) };
}

sub redeem_essentia_code {
    my ($self, $session_id, $code) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    $empire->redeem_essentia_code($code);
    return { status => $self->format_status($empire) };
}

sub invite_friend {
    my ($self, $session_id, $email) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    $empire->invite_friend($email);
    return { status => $self->format_status($empire) };
}


sub update_species {
    my ($self, $empire_id, $me) = @_;

    # make sure it's a valid empire
    unless ($empire_id ne '') {
        confess [1002, "You must specify an empire id."];
    }
    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($empire_id);
    unless (defined $empire) {
        confess [1002, "Not a valid empire.",'empire_id'];
    }

    # deal with an empire in motion
    if ($empire->stage ne 'new') {
        confess [1010, "You can't establish a new species for an empire that's already founded.",'empire_id'];
    }

    # make sure the name is valid
    $me->{name} =~ s{^\s+(.*)\s+$}{$1}xms; # remove extra white space
    Lacuna::Verify->new(content=>\$me->{name}, throws=>[1000,'Species name not available.', 'name'])
        ->length_lt(31)
        ->length_gt(2)
        ->not_empty
        ->no_restricted_chars
        ->no_profanity;

    # and the description        
    Lacuna::Verify->new(content=>\$me->{description}, throws=>[1005,'Description invalid.', 'description'])
        ->length_lt(1025)
        ->no_restricted_chars
        ->no_profanity;  
    
    # how about orbits
    unless ($me->{min_orbit} >= 1 && $me->{min_orbit} <= 7 && $me->{min_orbit} <= $me->{max_orbit}) {
        confess [1009, 'Minimum orbit must be between 1 and 7 and less than or equal to maximum orbit.','min_orbit'];
    }
    unless ($me->{max_orbit} >= 1 && $me->{max_orbit} <= 7 && $me->{max_orbit} >= $me->{min_orbit}) {
        confess [1009, 'Maximum orbit must be between 1 and 7 and greater than or equal to minimum orbit.','min_orbit'];
    }
 
    # deal with point allocation
    my $points = $me->{max_orbit} - $me->{min_orbit} + 1;
    foreach my $attr (qw(manufacturing_affinity deception_affinity research_affinity management_affinity farming_affinity mining_affinity science_affinity environmental_affinity political_affinity trade_affinity growth_affinity)) {
        $me->{$attr} += 0; # ensure it's a number
        if ($me->{$attr} < 1) {
            confess [1008, 'Too little to an affinity.', $attr];
        }
        elsif ($me->{$attr} > 7) {
            confess [1007, 'Too much to an affinity.', $attr];
        }
        $points += $me->{$attr};
    }
    if ($points > 45) {
        confess [1007, 'Overspend.'];
    }
    elsif ($points < 45) {
        confess [1008, 'Underspend.'];
    }

    $empire->species_name($me->{name});
    $empire->species_description($me->{description});
    $empire->min_orbit($me->{min_orbit});
    $empire->max_orbit($me->{min_orbit});
    $empire->manufacturing_affinity($me->{manufacturing_affinity});
    $empire->deception_affinity($me->{deception_affinity});
    $empire->research_affinity($me->{research_affinity});
    $empire->management_affinity($me->{management_affinity});
    $empire->farming_affinity($me->{farming_affinity});
    $empire->mining_affinity($me->{mining_affinity});
    $empire->science_affinity($me->{science_affinity});
    $empire->environmental_affinity($me->{environmental_affinity});
    $empire->political_affinity($me->{political_affinity});
    $empire->trade_affinity($me->{trade_affinity});
    $empire->growth_affinity($me->{growth_affinity});
    $empire->update;
    
    return 1;
}

sub view_species_stats {
    my ($self, $session_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    return {
        species => {
            name                    => $empire->species_name,
            description             => $empire->species_description,
            min_orbit               => $empire->min_orbit,
            max_orbit               => $empire->max_orbit,
            manufacturing_affinity  => $empire->manufacturing_affinity,
            deception_affinity      => $empire->deception_affinity,
            research_affinity       => $empire->research_affinity,
            management_affinity     => $empire->management_affinity,
            farming_affinity        => $empire->farming_affinity,
            mining_affinity         => $empire->mining_affinity,
            science_affinity        => $empire->science_affinity,
            environmental_affinity  => $empire->environmental_affinity,
            political_affinity      => $empire->political_affinity,
            trade_affinity          => $empire->trade_affinity,
            growth_affinity         => $empire->growth_affinity,
        },
        status  => $self->format_status($empire),
    };
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

__PACKAGE__->register_rpc_method_names(
    { name => "create", options => { with_plack_request => 1 } },
    { name => "fetch_captcha", options => { with_plack_request => 1 } },
    { name => "login", options => { with_plack_request => 1 } },
    { name => "found", options => { with_plack_request => 1 } },
    { name => "reset_password", options => { with_plack_request => 1 } },
    qw(get_species_templates update_species view_species_stats send_password_reset_message invite_friend redeem_essentia_code enable_self_destruct disable_self_destruct change_password set_status_message find view_profile edit_profile view_public_profile is_name_available logout get_full_status get_status boost_storage boost_water boost_energy boost_ore boost_food boost_happiness view_boosts),
);


no Moose;
__PACKAGE__->meta->make_immutable;

