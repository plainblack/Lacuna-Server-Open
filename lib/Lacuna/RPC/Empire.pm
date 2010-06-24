package Lacuna::RPC::Empire;

use Moose;
extends 'Lacuna::RPC';
use Lacuna::Util qw(format_date);
use DateTime;

sub find {
    my ($self, $session_id, $name) = @_;
    unless (length($name) >= 3) {
        confess [1009, 'Empire name too short. Your search must be at least 3 characters.'];
    }
    my $empire = $self->get_empire_by_session($session_id);
    my $empires = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({name => {'like' => '%'.$name.'%'}}, {rows=>100});
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
        confess [1004, 'Password incorrect.', $password];
    }
    return { session_id => $empire->start_session($api_key)->id, status => $self->format_status($empire) };
}


sub fetch_captcha {
    my ($self, $plack_request) = @_;
    my $ip = $plack_request->address;
    my $captcha = Lacuna->db->resultset('Lacuna::DB::Result::Captcha')->find(randint(1,72792));
    Lacuna->cache->set('create_empire_captcha', $ip, { guid => $captcha->guid, solution => $captcha->solution }, 60 * 15 );
    return {
        guid    => $captcha->guid,
        url     => 'https://extras.lacunaexpanse.com.s3.amazonaws.com/captcha/'.substr($captcha->guid,0,2).'/'.$captcha->guid.'.png',
    };
}

sub create {
    my ($self, $plack_request, %account) = @_;
    Lacuna::Verify->new(content=>\$account{password}, throws=>[1001,'Invalid password.', $account{password}])
        ->length_gt(5)
        ->eq($account{password1});

if ($account{captcha_guid}) {
    $self->validate_captcha($plack_request, $account{captcha_guid}, $account{captcha_solution});
}

    $self->is_name_available($account{name});

    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->new({
        name                => $account{name},
        species_id          => 2,
        status_message      => 'Making Lacuna a better Expanse.',
        password            => Lacuna::DB::Result::Empire->encrypt_password($account{password}),

    })->insert;
    
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
        status_message  => $empire->status_message,
        medals          => \%my_medals,
    );
    return { profile => \%out, status => $self->format_status($empire) };    
}

sub edit_profile {
    my ($self, $session_id, $profile) = @_;
    Lacuna::Verify->new(content=>\$profile->{description}, throws=>[1005,'Description invalid.', 'description'])
        ->length_lt(1025)
        ->no_restricted_chars
        ->no_profanity;  
    Lacuna::Verify->new(content=>\$profile->{status_message}, throws=>[1005,'Status message invalid.', 'status_message'])
        ->length_lt(101)
        ->not_empty
        ->no_restricted_chars
        ->no_profanity;
    unless (ref $profile->{public_medals} eq  'ARRAY') {
        confess [1009, 'Medals list needs to be an array reference.', 'public_medals'];
    }
    
    # preferences
    my $empire = $self->get_empire_by_session($session_id);
    $empire->description($profile->{description});
    $empire->status_message($profile->{status_message});
    $empire->update;

    # medals
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


__PACKAGE__->register_rpc_method_names(
    { name => "create", options => { with_plack_request => 1 } },
    { name => "fetch_captcha", options => { with_plack_request => 1 } },
    qw(set_status_message find view_profile edit_profile view_public_profile is_name_available found login logout get_full_status get_status boost_water boost_energy boost_ore boost_food boost_happiness view_boosts),
);


no Moose;
__PACKAGE__->meta->make_immutable;

