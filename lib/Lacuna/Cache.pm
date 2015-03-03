package Lacuna::Cache;

use strict;
use Moose;
use utf8;
no warnings qw(uninitialized);
use Memcached::libmemcached;
use JSON;

has 'servers' => (
    is          => 'ro',
    required    => 1,
);

has 'memcached' => (
    is  => 'ro',
    lazy    => 1,
    clearer => 'clear_memcached',
    default => sub {
        my $self = shift;
        my $memcached = Memcached::libmemcached::memcached_create();
        foreach my $server (@{$self->servers}) {
            if (exists $server->{socket}) {
                Memcached::libmemcached::memcached_server_add_unix_socket($memcached, $server->{socket}); 
            }
            else {
                Memcached::libmemcached::memcached_server_add($memcached, $server->{host}, $server->{port});
            }
        }
        return $memcached;
    },
);

sub fix_key {
    my ($self, $namespace, $id) = @_;
    my $key = $namespace.":".$id;
    $key =~ s/\s+/_/g;
    return $key;
}

sub delete {
    my ($self, $namespace, $id, $retry) = @_;
    my $key = $self->fix_key($namespace, $id);
    my $memcached = $self->memcached;
    Memcached::libmemcached::memcached_delete($memcached, $key);
    if ($memcached->errstr eq 'SYSTEM ERROR Unknown error: 0') {
        warn "Cannot connect to memcached server.";
    }
    elsif ($memcached->errstr eq 'UNKNOWN READ FAILURE' ) {
        if ($retry) {
            warn "Cannot connect to memcached server.";
        }
        else {
            warn "Memcached went away, reconnecting.";
            $self->clear_memcached;
            $self->delete($namespace, $id, 1);
        }
    }
    elsif ($memcached->errstr eq 'NO SERVERS DEFINED') {
        warn "No memcached servers specified.";
    }
    elsif ($memcached->errstr ne 'SUCCESS' # deleted
        && $memcached->errstr ne 'PROTOCOL ERROR' # doesn't exist to delete
        && $memcached->errstr ne 'NOT FOUND' # doesn't exist to delete
        ) {
        warn "Couldn't delete $key from cache because ".$memcached->errstr;
    }
}

sub flush {
    my ($self, $retry) = @_;
    my $memcached = $self->memcached;
    Memcached::libmemcached::memcached_flush($memcached);
    if ($memcached->errstr eq 'SYSTEM ERROR Unknown error: 0') {
        warn "Cannot connect to memcached server.";
    }
    elsif ($memcached->errstr eq 'UNKNOWN READ FAILURE' ) {
        confess "Cannot connect to memcached server." if $retry;
        warn "Memcached went away, reconnecting.";
        $self->clear_memcached;
        return $self->flush(1);
    }
    elsif ($memcached->errstr eq 'NO SERVERS DEFINED') {
        warn "No memcached servers specified.";
    }
    elsif ($memcached->errstr ne 'SUCCESS') {
        warn "Couldn't flush cache because ".$memcached->errstr;
    }
}

sub get {
    my ($self, $namespace, $id, $retry) = @_;
    my $key = $self->fix_key($namespace, $id);
    my $memcached = $self->memcached;
    my $content = Memcached::libmemcached::memcached_get($memcached, $key);
    if ($memcached->errstr eq 'SUCCESS') {
        return $content;
    }
    elsif ($memcached->errstr eq 'NOT FOUND' ) {
        return undef;
    }
    elsif ($memcached->errstr eq 'NO SERVERS DEFINED') {
        warn "No memcached servers specified.";
        return undef;
    }
    elsif ($memcached->errstr eq 'SYSTEM ERROR Unknown error: 0' || $retry) {
        warn "Cannot connect to memcached server.";
        return undef;
    }
    elsif ($memcached->errstr eq 'UNKNOWN READ FAILURE' ) {
        warn "Memcached went away, reconnecting.";
        $self->clear_memcached;
        return $self->get($namespace, $id, 1);
    }
    warn "Couldn't get $key from cache because [".$memcached->errstr."]";
}

sub get_and_deserialize {
    my ($self, $namespace, $id) = @_;
    my $value = $self->get($namespace, $id);
    $value = eval{JSON::from_json($value)} if ($value);
    warn $@ if ($@);
    return $value;
}

sub add {
    my ($self, $namespace, $id, $value, $ttl, $retry) = @_;
    my $key = $self->fix_key($namespace, $id);
    $ttl ||= 60;
    my $frozenValue = (ref $value) ? JSON::to_json($value) : $value; 
    my $memcached = $self->memcached;
    Memcached::libmemcached::memcached_add($memcached, $key, $frozenValue, $ttl);
    if ($memcached->errstr eq 'SUCCESS') {
        return $value;
    }
    elsif ($memcached->errstr eq 'NOT STORED') {
        # already exists in cache
        return undef;
    }
    elsif ($memcached->errstr eq 'SYSTEM ERROR Unknown error: 0' || $retry) {
        warn "Cannot connect to memcached server.";
    }
    elsif ($memcached->errstr eq 'UNKNOWN READ FAILURE' ) {
        warn "Memcached went away, reconnecting.";
        $self->clear_memcached;
        return $self->set($namespace, $id, $value, $ttl, 1);
    }
    elsif ($memcached->errstr eq 'NO SERVERS DEFINED') {
        warn "No memcached servers specified.";
    }
    warn "Couldn't set $key to cache because ".$memcached->errstr;
}


sub set {
    my ($self, $namespace, $id, $value, $ttl, $retry) = @_;
    my $key = $self->fix_key($namespace, $id);
    $ttl ||= 60;
    my $frozenValue = (ref $value) ? JSON::to_json($value) : $value; 
    my $memcached = $self->memcached;
    Memcached::libmemcached::memcached_set($memcached, $key, $frozenValue, $ttl);
    if ($memcached->errstr eq 'SUCCESS') {
        return $value;
    }
    elsif ($memcached->errstr eq 'SYSTEM ERROR Unknown error: 0' || $retry) {
        warn "Cannot connect to memcached server.";
    }
    elsif ($memcached->errstr eq 'UNKNOWN READ FAILURE' ) {
        warn "Memcached went away, reconnecting.";
        $self->clear_memcached;
        return $self->set($namespace, $id, $value, $ttl, 1);
    }
    elsif ($memcached->errstr eq 'NO SERVERS DEFINED') {
        warn "No memcached servers specified.";
    }
    warn "Couldn't set $key to cache because ".$memcached->errstr;
}


sub increment {
    my ($self, $namespace, $id, $amount, $ttl, $retry) = @_;
    my $key = $self->fix_key($namespace, $id);
    $amount ||= 1;
    $ttl ||= 60;
    my $memcached = $self->memcached;
    my $new_tally;
    Memcached::libmemcached::memcached_increment($memcached, $key, $amount, $new_tally);
    if ($memcached->errstr eq 'SUCCESS') {
        return $new_tally;
    }
    elsif ($memcached->errstr eq 'NOT FOUND') {
        return $self->set($namespace, $id, $amount, $ttl);
    }
    elsif ($memcached->errstr eq 'SYSTEM ERROR Unknown error: 0' || $retry) {
        warn "Cannot connect to memcached server.";
    }
    elsif ($memcached->errstr eq 'UNKNOWN READ FAILURE' ) {
        warn "Memcached went away, reconnecting.";
        $self->clear_memcached;
        return $self->set($namespace, $id, $amount, 1);
    }
    elsif ($memcached->errstr eq 'NO SERVERS DEFINED') {
        warn "No memcached servers specified.";
    }
    warn "Couldn't set $key to cache because ".$memcached->errstr;
}


no Moose;
__PACKAGE__->meta->make_immutable;

