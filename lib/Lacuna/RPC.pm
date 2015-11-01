package Lacuna::RPC;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'JSON::RPC::Dispatcher::App';
use Lacuna::Util qw(format_date real_ip_address);
use Log::Any qw($log);

has plack_request => ( is => 'rw' );

sub get_session {
    my ($self, $opts) = @_;
    my $session = ref $opts ? $opts->{session_id} : $opts;

    if (ref $session ne 'Lacuna::Session') {
        if (ref $session eq 'Lacuna::DB::Result::Empire') {
            $session = $session->start_session;
        }
        else {
            my $session_id = $session;
            $session = Lacuna::Session->new(id=>$session);
            if ($session && $session->empire_id) {
                $session->extend;
            }
            else {
                confess [1006, 'Session expired.', $session_id];
            }
        }
    }
    $opts = { session_id => $session->id } unless ref $opts;

    if ($opts->{building_id}) {
        my $building = $self->get_building($session,
                                           $opts->{building_id},
                                           %$opts);
        $session->current_building($building);
        $session->current_body($building->body);
        if ($session->current_body->isa('Lacuna::DB::Result::Map::Body::Planet::Station'))
        {
            # all station access is as yourself.
            $session->current_empire($session->empire);
        }
        else
        {
            $session->current_empire($session->current_body->empire);
        }
    }
    elsif ($opts->{body_id}) {
        my $body = $self->get_body($session,
                                   $opts->{body_id});
        $session->clear_building;
        $session->current_body($body);
        if ($session->current_body->isa('Lacuna::DB::Result::Map::Body::Planet::Station'))
        {
            # all station access is as yourself.
            $session->current_empire($session->empire);
        }
        else
        {
            $session->current_empire($session->current_body->empire);
        }
    }

    $session->current_empire($session->empire)
        unless $session->current_empire;
    $session->current_empire->current_session($session);

    my $empire = $session->current_empire;
    if (defined $empire) {
        my $throttle = Lacuna->config->get('rpc_throttle') || 30;
        if (my $delay = Lacuna->cache->get('rpc_block', $opts->{session_id})) {
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
        if (!$session->ip_address && $ipr) {
            $log->debug("Missing IP address, adding $ipr");
            $session->ip_address($ipr);
            $session->update;
        }
        my $ipm = $session->ip_address eq $ipr;
        my $i = 1;
        my @caller = caller($i);
        while (@caller)
        {
            last if $caller[0] =~ /Lacuna::RPC/;
            @caller = caller(++$i);
        }
        $log->info(sprintf "ACTUAL:ipr=%s,ipe=%s,ipm=%s,ses=%s,sat:%d,rpc=%s", $ipr, $session->ip_address, $ipm, $opts->{session_id}, $session->is_sitter ? 1 : 0, $caller[3]);
        #Lacuna->db->resultset('Lacuna::DB::Result::Log::RPC')->new({
        #   empire_id    => $empire->id,
        #   empire_name  => $empire->name,
        #   module       => ref $self,
        #   api_key      => $empire->current_session->api_key,
        #})->insert;
    }
    else {
        confess [1002, 'Empire does not exist.'];
    }

    if ($session->current_body) {
        if ($session->current_body->id eq $session->current_empire->home_planet_id) {
            $session->current_empire->home_planet($session->current_body);
        }

        $session->current_body->tick;
        # do we need to discard the changes?
    }

    return $session;
}

sub get_body { # makes for uniform error handling, and prevents staleness
    my ($self, $session, $body_id) = @_;
    my $body;
    if (ref $body_id && $body_id->isa('Lacuna::DB::Result::Map::Body')) {
        $body = $body_id;
    } else {
        $body = Lacuna->db->resultset('Map::Body')->
            search(
                   {
                       'me.id' => $body_id,
                       -or => [
                               { 'me.empire_id'        => $session->empire->id },
                               { 'me.alliance_id'      => $session->empire->alliance_id },
                               $session->_is_sitter ?
                               {
                                   'sitterauths.sitter_id' => $session->empire->id,
                                   'me.class' => { '!=' => 'Lacuna::DB::Result::Map::Body::Planet::Station' },
                               } : (),
                              ]
                   },
                   {
                       join => { 'empire' => 'sitterauths' },
                       prefetch => [ 'empire' ],
                   }
                  )->first;
        confess [ 1002, 'Body does not exist or is not owned by you or any empire you sit.', $body_id ]
            unless $body;

    }
    return $body;
}

sub get_building { # makes for uniform error handling, and prevents staleness
    my ($self, $session, $building_id, %options) = @_;
    if (ref $building_id && $building_id->isa('Lacuna::DB::Result::Building')) {
        return $building_id;
    }

    my $building =
        Lacuna->db->resultset('Building')->
        search(
               {
                   'me.id' => $building_id,
                   -or => [
                           { 'body.empire_id'        => $session->empire->id },
                           { 'body.alliance_id'      => $session->empire->alliance_id },
                           $session->_is_sitter ?
                           {
                               'sitterauths.sitter_id' => $session->empire->id,
                               'body.class' => { '!=' => 'Lacuna::DB::Result::Map::Body::Planet::Station' },
                           } : (),
                          ]
               },
               {
                   join => { body => { 'empire' => 'sitterauths' }},
                   prefetch => { body => 'empire' },
               }
              )->first;
    confess [ 1002, 'Building does not exist or is not owned by you or any empire you sit.', $building_id ]
        unless $building;

    confess [ 1002, 'That building is not a '. $self->model_class->name ]
        unless $building->class eq $self->model_class;

    $building->is_offline unless $options{skip_offline};

    return $building;
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

        if (my @promos = Lacuna->db->resultset('Promotion')->current_promotions)
        {
            $out{server}{promotions} = [ map $_->ui_details, @promos ];
        }
    }
    if (defined $body) {
        $out{body} = $body->get_status($empire->current_session->empire);
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
