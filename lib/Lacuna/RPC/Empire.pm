package Lacuna::RPC::Empire;

use Moose;
extends 'Lacuna::RPC';
use Lacuna::Util qw(format_date);
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
    my ($self, $name, $password, $api_key) = @_;
    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({name=>$name})->next;
    unless (defined $empire) {
         confess [1002, 'Empire does not exist.', $name];
    }
    if ($empire->stage eq 'new') {
        confess [1010, "You can't log in to an empire that has not been founded."];
    }
    unless ($empire->is_password_valid($password)) {
        if ($password ne '' && $empire->sitter_password eq $password) {
            return { session_id => $empire->start_session($api_key, 1)->id, status => $self->format_status($empire) };
        }
        else {
            confess [1004, 'Password incorrect.', $password];            
        }
    }
    return { session_id => $empire->start_session($api_key)->id, status => $self->format_status($empire) };
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
    unless (defined $empire) {
        confess [1002, 'That empire has no email address specified.'];
    }
    $empire->password_recovery_key(create_UUID_as_string(UUID_V4));
    $empire->update;
    
    my $message = "Use the key or the link below to reset the password for %s.\n\nKey: %s\n\n%s?reset_password=%s";
    $empire->send_email(
        'Reset Your Password',
        sprintf($message, $empire->name, $empire->password_recovery_key, Lacuna->config->get('server_url'), $empire->password_recovery_key),
    );
    return { sent => 1 };
}


sub reset_password {
    my ($self, $key, $password1, $password2, $api_key) = @_;
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
    return { session_id => $empire->start_session($api_key)->id, status => $self->format_status($empire) };
}


sub create {
    my ($self, $plack_request, %account) = @_;    
    my %params = (
        species_id          => 2,
        status_message      => 'Making Lacuna a better Expanse.',
        sitter_password     => random_string('CC.c!ccn'),
    );

if ($account{captcha_guid}) { # get rid of this IF before we go live
    # verify captcha
    $self->validate_captcha($plack_request, $account{captcha_guid}, $account{captcha_solution});
}

    # check facebook    
    my $has_facebook = (exists $account{facebook_uid} && $account{facebook_uid} =~ m/^\d+$/ && exists $account{facebook_token} && lenght($account{facebook_token}) > 60);
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
    confess [1014, 'Captcha not valid.', $self->assign_captcha($plack_request)];
}

sub found {
    my ($self, $empire_id, $api_key) = @_;
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
    $empire = $empire->found;
    return { session_id => $empire->start_session($api_key)->id, status => $self->format_status($empire) };
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
        description     => $empire->description,
        notes           => $empire->notes,
        status_message  => $empire->status_message,
        sitter_password => $empire->sitter_password,
        email           => $empire->email,
        city            => $empire->city,
        country         => $empire->country,
        skype           => $empire->skype,
        player_name     => $empire->player_name,
        medals          => \%my_medals,
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
        Lacuna::Verify->new(content=>\$profile->{sitter_password}, throws=>[1005,'Sitter password must be between 8 and 30 characters.', 'sitter_password'])
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
        if (Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({email=>$profile->{email}, empire_id=>{ '!=' => $empire->id}})->count > 0) {
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
        species         => $viewed_empire->species->name,
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



__PACKAGE__->register_rpc_method_names(
    { name => "create", options => { with_plack_request => 1 } },
    { name => "fetch_captcha", options => { with_plack_request => 1 } },
    qw(redeem_essentia_code enable_self_destruct disable_self_destruct change_password set_status_message find view_profile edit_profile view_public_profile is_name_available found login logout get_full_status get_status boost_water boost_energy boost_ore boost_food boost_happiness view_boosts),
);


no Moose;
__PACKAGE__->meta->make_immutable;

