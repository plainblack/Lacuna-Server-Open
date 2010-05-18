package Lacuna::RPC;

use Moose;
extends 'JSON::RPC::Dispatcher::App';
use Lacuna::Util qw(format_date);


sub get_session {
    my ($self, $session_id) = @_;
    if (ref $session_id eq 'Lacuna::DB::Result::Session') {
        return $session_id;
    }
    else {
        my $session = Lacuna::Session->new(id=>$session_id);
        if (!defined $session) {
            confess [1006, 'Session expired.', $session_id];
        }
        else {
            $session->extend;
            return $session;
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
            return $empire;
        }
        else {
            confess [1002, 'Empire does not exist.'];
        }
    }
}

sub get_body { # makes for uniform error handling, and prevents staleness
    my ($self, $body_id) = @_;
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($body_id);
    unless (defined $body) {
        confess [1002, 'Body does not exist.', $body_id];
    }
    unless ($body->empire_id eq $self->id) {
        confess [1010, "Can't manipulate a planet you don't inhabit."];
    }
    $body->empire($self);
    if ($body->id eq $self->home_planet_id) {
        $self->home_planet($body);
    }
    return $body;
}

sub get_building { # makes for uniform error handling, and prevents staleness
    my ($self, $class, $building_id) = @_;
    if (ref $building_id && $building_id->isa('Lacuna::DB::Result::Building')) {
        return $building_id;
    }
    else {
        my $building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->find($building_id);
        unless (defined $building) {
            confess [1002, 'Building does not exist.', $building_id];
        }
        if ($building->class ne $self->model_class) {
            confess [1002, 'That building is not a '.$class->name];
        }
        $building->is_offline;
        my $body = $self->get_body($building->body_id);        
        if ($body->empire_id ne $self->id) { 
            confess [1010, "Can't manipulate a building that you don't own.", $building_id];
        }
        $body->tick;
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
