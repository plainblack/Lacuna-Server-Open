package Lacuna::Empire;

use Moose;
extends 'JSON::RPC::Dispatcher::App';
use Lacuna::Util qw(cname format_date);
use Lacuna::Map;
use Lacuna::Verify;
use Lacuna::Constants qw(MEDALS);
use DateTime;

has simpledb => (
    is      => 'ro',
    required=> 1,
);

with 'Lacuna::Role::Sessionable';


sub find {
    my ($self, $session_id, $name) = @_;
    unless (length($name) >= 3) {
        confess [1009, 'Empire name too short. Your search must be at least 3 characters.'];
    }
    my $empire = $self->get_empire_by_session($session_id);
    my $empires = $self->simpledb->domain('empire')->search(where=>{name_cname => ['like', '%'.cname($name).'%']}, limit=>100);
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
    return { empires => \@list_of_empires, status => $empire->get_status };
}

sub is_name_available {
    my ($self, $name) = @_;
    Lacuna::Verify->new(content=>\$name, throws=>[1000,'Empire name not available.', 'name'])
        ->length_lt(31)
        ->length_gt(2)
        ->not_empty
        ->no_restricted_chars
        ->no_profanity
        ->ok( !$self->simpledb->domain('empire')->count(where=>{name_cname=>cname($name)}, consistent=>1) );
    return 1; 
}

sub logout {
    my ($self, $session_id) = @_;
    $self->get_session($session_id)->delete;
    return 1;
}

sub login {
    my ($self, $name, $password) = @_;
    my $empire = $self->simpledb->domain('empire')->search(where=>{name_cname=>cname($name)})->next;
    unless (defined $empire) {
         confess [1002, 'Empire does not exist.', $name];
    }
    if ($empire->stage eq 'new') {
        confess [1010, "You can't log in to an empire tha has not been founded."];
    }
    unless ($empire->is_password_valid($password)) {
        confess [1004, 'Password incorrect.', $password];
    }
    return { session_id => $empire->start_session->id, status => $empire->get_full_status };
}

sub create {
    my ($self, %account) = @_;
    Lacuna::Verify->new(content=>\$account{password}, throws=>[1001,'Invalid password.', $account{password}])
        ->length_gt(5)
        ->eq($account{password1});

    $self->is_name_available($account{name});

    my $empire = Lacuna::DB::Empire->create($self->simpledb, \%account);
    return $empire->id;
}


sub found {
    my ($self, $empire_id) = @_;
    if ($empire_id eq '') {
        confess [1002, "You must specify an empire id."];
    }
    my $empire = $self->simpledb->domain('empire')->find($empire_id);
    unless (defined $empire) {
        confess [1002, "Invalid empire.", $empire_id];
    }
    unless ($empire->stage eq 'new') {
        confess [1010, "This empire cannot be founded again.", $empire_id];
    }
    $empire = $empire->found;
    return { session_id => $empire->start_session->id, status => $empire->get_full_status };
}

sub get_status {
    my ($self, $session_id) = @_;
    return $self->get_empire_by_session($session_id)->get_status;
}

sub get_full_status {
    my ($self, $session_id) = @_;
    return $self->get_empire_by_session($session_id)->get_full_status;
}

sub view_profile {
    my ($self, $session_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $medals = $empire->medals;
    my %my_medals;
    foreach my $key (keys %{$medals}) {
        $my_medals{$key} = {
            name    => MEDALS->{$key},
            image   => $key,
            date    => $medals->{$key}{date},
            note    => $medals->{$key}{note},
            public  => $medals->{$key}{public}
        };
    }
    my %out = (
        description     => $empire->description,
        status_message  => $empire->status_message,
        medals          => \%my_medals,
    );
    return { profile => \%out, status => $empire->get_status };    
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
    my $empire = $self->get_empire_by_session($session_id);
    $empire->description($profile->{description});
    $empire->status_message($profile->{status_message});
    my $medals = $empire->medals;
    foreach my $key (keys %{$medals}) {
        if ($key ~~ $profile->{public_medals}) {
            $medals->{$key}{public} = 1;
        }
        else {
            $medals->{$key}{public} = 0;
        }
    }
    $empire->medals($medals);
    $empire->put;
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
    $empire->put;
    return $empire->get_status;
}

sub view_public_profile {
    my ($self, $session_id, $empire_id) = @_;
    my $viewer_empire = $self->get_empire_by_session($session_id);
    my $viewed_empire = $self->simpledb->domain('empire')->find($empire_id);
    unless (defined $viewed_empire) {
        confess [1002, 'The empire you wish to view does not exist.', $empire_id];
    }
    my $medals;
    my %public_medals;
    foreach my $key (keys %{$medals}) {
        next unless $medals->{$key}{public};
        $public_medals{$key} = {
            image   => $key,
            name    => MEDALS->{$key},
            date    => $medals->{$key}{date},
            note    => $medals->{$key}{note},
        };
    }
    my %out = (
        id              => $viewed_empire->id,
        name            => $viewed_empire->name,
        description     => $viewed_empire->description,
        status_message  => $viewed_empire->status_message,
        species         => $viewed_empire->species->name,
        date_founded    => format_date($viewed_empire->date_created),
        planet_count    => $self->simpledb->domain('Lacuna::DB::Body::Planet')->count(where=>{empire_id=>$viewed_empire->id}),
        medals          => \%public_medals,
    );
    return { profile => \%out, status => $viewer_empire->get_status };
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
    $empire->spend_essentia(5);
    my $start = DateTime->now;
    $start = $empire->$type if ($empire->$type > $start);
    $start->add(days=>7);
    $empire->planets->update({needs_recalc=>1});
    $empire->$type($start);
    $empire->trigger_full_update(skip_put=>1);
    $empire->put;
    return {
        status => $empire->get_status,
        $type => format_date($empire->$type),
    };
}

sub view_boosts {
    my ($self, $session_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    return {
        status  => $empire->get_status,
        boosts  => {
            food        => format_date($empire->food_boost),
            happiness   => format_date($empire->happiness_boost),
            water       => format_date($empire->water_boost),
            ore         => format_date($empire->ore_boost),
            energy      => format_date($empire->energy_boost),
        }
    };
}


__PACKAGE__->register_rpc_method_names(qw(set_status_message find view_profile edit_profile view_public_profile is_name_available create found login logout get_full_status get_status boost_water boost_energy boost_ore boost_food boost_happiness view_boosts));


no Moose;
__PACKAGE__->meta->make_immutable;

