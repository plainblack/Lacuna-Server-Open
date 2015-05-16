package Lacuna::RPC;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'JSON::RPC::Dispatcher::App';
use Lacuna::Util qw(format_date real_ip_address);
use Log::Any qw($log);

has plack_request => ( is => 'rw' );

sub get_session {
    my ($self, $session_id) = @_;
    if (ref $session_id eq 'Lacuna::Session') {
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
        my $session = $self->get_session($session_id);
        my $empire = $session->empire;
        if (defined $empire) {
            my $throttle = Lacuna->config->get('rpc_throttle') || 30;
            if (my $delay = Lacuna->cache->get('rpc_block', $session_id)) {
                confess [1010, 'Too fast response, ' . $empire->name . '!'];
            }
            if ($empire->rpc_rate > $throttle) {
                Lacuna->cache->increment('rpc_limit_'.format_date(undef,'%d'), $empire->id, 1, 60 * 60 * 30);
                confess [1010, 'Slow down '.$empire->name.'! No more than '.$throttle.' requests per minute.'];
            }
            my $max = Lacuna->config->get('rpc_limit') || 2500;
            if ($empire->rpc_count > $max) {
                confess [1010, $empire->name.' has already made the maximum number of requests ('.$max.') you can make for one day.'];
            }
            my $ipr = real_ip_address($self->plack_request);
            if (!$session->ip_address) {
                $log->debug("Missing IP address, adding $ipr");
                $session->ip_address($ipr);
                $session->update;
            }
            my $ipm = $session->ip_address eq $ipr;
            my @caller;
            for (my $i = 1;$caller[0] !~ /Lacuna::RPC/;++$i) {
                @caller = caller($i);
            }
            $log->info(sprintf "ACTUAL:ipr=%s,ipe=%s,ipm=%s,ses=%s,sat:%d,rpc=%s", $ipr, $session->ip_address, $ipm, $session_id, $session->is_sitter ? 1 : 0, $caller[3]);
            #Lacuna->db->resultset('Lacuna::DB::Result::Log::RPC')->new({
            #   empire_id    => $empire->id,
            #   empire_name  => $empire->name,
            #   module       => ref $self,
            #   api_key      => $empire->current_session->api_key,
            #})->insert;
            return $empire;
        }
        else {
            confess [1002, 'Empire does not exist.'];
        }
    }
}

sub get_body { # makes for uniform error handling, and prevents staleness
    my ($self, $empire, $body_id) = @_;
    my $body;
    if (ref $body_id && $body_id->isa('Lacuna::DB::Result::Map::Body')) {
        $body = $body_id;
    }
    else {
        ($body) = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({
            'me.id' => $body_id,
        },{
            prefetch => 'empire',
        });
    }
    unless (defined $body) {
        confess [1002, 'Body does not exist.', $body_id];
    }
    if ($body->empire_id ne $empire->id) {
        if ($body->isa('Lacuna::DB::Result::Map::Body::Planet::Station')) {
            if ($body->empire->alliance_id eq $empire->alliance_id) {
                $body->tick;
                return $body;
            }
        }
        confess [1010, "Can't manipulate a planet you don't inhabit."];
    }
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
        my ($building) = Lacuna->db->resultset('Lacuna::DB::Result::Building')->search({
            'me.id' => $building_id,
        },{ prefetch => 'body' }
        );

        unless (defined $building) {
            confess [1002, 'Building does not exist.', $building_id];
        }
        if ($building->class ne $self->model_class) {
            confess [1002, 'That building is not a '.$self->model_class->name];
        }
        $building->is_offline unless ($options{skip_offline});
        my $body = $self->get_body($empire, $building->body);        
        if ($body->empire_id ne $empire->id) { 
            if ($body->isa('Lacuna::DB::Result::Map::Body::Planet::Station')) {
                if ($body->empire->alliance_id eq $empire->alliance_id) {
                    $building->discard_changes; # in case it changed due to the tick
                    $building->body($body);
                    return $building;
                }
            }
            confess [1010, "Can't manipulate a building that you don't own.", $building_id];
        }
        $building->discard_changes; # in case it changed due to the tick
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
            rpc_limit       => Lacuna->config->get('rpc_limit') || 2500,
        },
    );
    if (defined $empire) {
        my $cache = Lacuna->cache;
        my $alert = $cache->get('announcement','alert');
        if ($alert && !$cache->get('announcement'.$alert, $empire->id)) {
            $out{server}{announcement} = 1;
        }
        $out{empire} = $empire->get_status;
    }
    if (defined $body) {
        $out{body} = $body->get_status($empire);
    }
    return \%out;
}

sub to_app {
    my $self = shift;
    my $rpc = JSON::RPC::Dispatcher->new;
    my $ref;
    if ($ref = $self->can('_rpc_method_names')) {
        foreach my $method ($ref->()) {
            if (ref $method eq 'HASH') {
                my $name = $method->{name};
                if ($method->{options}{with_plack_request}) {
                    $rpc->register($name, sub { $self->plack_request($_[0]); $self->$name(@_) }, $method->{options});
                }
                else {
                    $rpc->register($name, sub { $self->plack_request(shift); $self->$name(@_) }, { with_plack_request => 1, %{$method->{options}} });
                }
            }
            else {
                $rpc->register($method, sub { $self->plack_request(shift); $self->$method(@_) }, { with_plack_request => 1} );
            }
        }
    }
    $rpc->to_app;
}

no Moose;
__PACKAGE__->meta->make_immutable;
