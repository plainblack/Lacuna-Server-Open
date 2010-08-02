package Lacuna::RPC;

use Moose;
no warnings qw(uninitialized);
extends 'JSON::RPC::Dispatcher::App';
use Lacuna::Util qw(format_date);



sub get_session {
    my ($self, $session_id) = @_;
    if (ref $session_id eq 'Lacuna::DB::Result::Session') {
        return $session_id;
    }
    else {
        my $session = Lacuna::Session->new(id=>$session_id);
        if ($session->empire_id) {
            $session->extend;
            return $session;
        }
        else {
            confess [1006, 'Session expired.', $session_id];
        }
    }
}

sub get_empire_by_session {
    my ($self, $session_id) = @_;
    if (ref $session_id eq 'Lacuna::DB::Result::Empire') {
        return $session_id;
    }
    else {
        my $empire = $self->get_session($session_id)->empire;
        if (defined $empire) {
            my $cache = Lacuna->cache;
            my $cache_key = 'rpc_count_'.format_date(undef,'%d');
            my $rpc_count = $cache->get($cache_key,$empire->id) + 1;
            if ($rpc_count > 12500) {
                confess [1010, 'You have already made the maximum number of requests (2500) you can make for one day.'];
            }
            $cache->set($cache_key, $empire->id, $rpc_count, 60 * 60 * 24);
            return $empire;
        }
        else {
            confess [1002, 'Empire does not exist.'];
        }
    }
}

sub get_body { # makes for uniform error handling, and prevents staleness
    my ($self, $empire, $body_id) = @_;
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($body_id);
    unless (defined $body) {
        confess [1002, 'Body does not exist.', $body_id];
    }
    unless ($body->empire_id eq $empire->id) {
        confess [1010, "Can't manipulate a planet you don't inhabit."];
    }
    $body->empire($empire);
    if ($body->id eq $empire->home_planet_id) {
        $empire->home_planet($body);
    }
    $body->tick;
    return $body;
}

sub get_building { # makes for uniform error handling, and prevents staleness
    my ($self, $empire, $building_id, %options) = @_;
    if (ref $building_id && $building_id->isa('Lacuna::DB::Result::Building')) {
        return $building_id;
    }
    else {
        my $building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->find($building_id);
        unless (defined $building) {
            confess [1002, 'Building does not exist.', $building_id];
        }
        if ($building->class ne $self->model_class) {
            confess [1002, 'That building is not a '.$self->model_class->name];
        }
        $building->is_offline unless ($options{skip_offline});
        my $body = $self->get_body($empire, $building->body_id);        
        if ($body->empire_id ne $empire->id) { 
            confess [1010, "Can't manipulate a building that you don't own.", $building_id];
        }
        $building->get_from_storage; # in case it changed due to the tick
        $building->body($body);
        return $building;
    }
}

sub format_status {
    my ($self, $empire, $body) = @_;
    my %out = (
        server  => {
            time            => format_date(DateTime->now),
            version         => Lacuna->version,
            star_map_size   => Lacuna->config->get('map_size'),
        },
    );
    if (defined $empire) {
        $out{empire} = $empire->get_status;
    }
    if (defined $body) {
        $out{body} = $body->get_status($empire);
    }
    return \%out;
}


no Moose;
__PACKAGE__->meta->make_immutable;
