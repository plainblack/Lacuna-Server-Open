package Lacuna::Cache;

use strict;
use Moose;
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
        confess "Cannot connect to memcached server.";
    }
    elsif ($memcached->errstr eq 'UNKNOWN READ FAILURE' ) {
        if ($retry) {
            confess "Cannot connect to memcached server.";
        }
        else {
            warn "Memcached went away, reconnecting.";
            $self->clear_memcached;
            $self->delete($namespace, $id, 1);
        }
    }
    elsif ($memcached->errstr eq 'NOT FOUND' ) {
        confess "The cache key $key has no value.";
    }
    elsif ($memcached->errstr eq 'NO SERVERS DEFINED') {
        confess "No memcached servers specified.";
    }
    elsif ($memcached->errstr ne 'SUCCESS' # deleted
        && $memcached->errstr ne 'PROTOCOL ERROR' # doesn't exist to delete
        ) {
        confess "Couldn't delete $key from cache because ".$memcached->errstr;
    }
}

sub flush {
    my ($self, $retry) = @_;
    my $memcached = $self->memcached;
    Memcached::libmemcached::memcached_flush($memcached);
    if ($memcached->errstr eq 'SYSTEM ERROR Unknown error: 0') {
        confess "Cannot connect to memcached server.";
    }
    elsif ($memcached->errstr eq 'UNKNOWN READ FAILURE' ) {
        confess "Cannot connect to memcached server." if $retry;
        warn "Memcached went away, reconnecting.";
        $self->clear_memcached;
        return $self->flush(1);
    }
    elsif ($memcached->errstr eq 'NO SERVERS DEFINED') {
        confess "No memcached servers specified.";
    }
    elsif ($memcached->errstr ne 'SUCCESS') {
        confess "Couldn't flush cache because ".$memcached->errstr;
    }
}

sub get {
    my ($self, $namespace, $id, $retry) = @_;
    my $key = $self->fix_key($namespace, $id);
    my $memcached = $self->memcached;
    my $content = Memcached::libmemcached::memcached_get($memcached, $key);
    $content = JSON::from_json($content);
    if ($memcached->errstr eq 'SUCCESS') {
        if (ref $content) {
            return $content;
        }
        else {
            confess "Couldn't thaw value for $key.";
        }
    }
    elsif ($memcached->errstr eq 'NOT FOUND' ) {
        confess "The cache key $key has no value.";
    }
    elsif ($memcached->errstr eq 'NO SERVERS DEFINED') {
        confess "No memcached servers specified.";
    }
    elsif ($memcached->errstr eq 'SYSTEM ERROR Unknown error: 0' || $retry) {
        confess "Cannot connect to memcached server.";
    }
    elsif ($memcached->errstr eq 'UNKNOWN READ FAILURE' ) {
        warn "Memcached went away, reconnecting.";
        $self->clear_memcached;
        return $self->get($namespace, $id, 1);
    }
    confess "Couldn't get $key from cache because ".$memcached->errstr;
}

sub mget {
    my ($self, $names, $retry) = @_;
    my @keys = map { $self->fix_key(@{$_}) } @{ $names };
    my %result;
    my $memcached = $self->memcached;
    $memcached->mget_into_hashref(\@keys, \%result);
    if ($memcached->errstr eq 'SYSTEM ERROR Unknown error: 0') {
        confess "Cannot connect to memcached server.";
    }
    elsif ($memcached->errstr eq 'UNKNOWN READ FAILURE' ) {
        confess "Cannot connect to memcached server." if $retry;
        warn "Memcached went away, reconnecting.";
        $self->clear_memcached;
        return $self->get($names, 1);
    }
    elsif ($memcached->errstr eq 'NO SERVERS DEFINED') {
        confess "No memcached servers specified.";
    }
    # no other useful status messages are returned
    my @values;
    foreach my $key (@keys) {
        my $content = JSON::from_json($result{$key});
        unless (ref $content) {
            confess "Can't thaw object returned from memcache for $key.";
            next;
        }
        push @values, $content;
    }
    return \@values;
}

sub set {
    my ($self, $namespace, $id, $value, $ttl, $retry) = @_;
    my $key = $self->fix_key($namespace, $id);
    $ttl ||= 60;
    my $frozenValue = JSON::to_json($value); 
    my $memcached = $self->memcached;
    Memcached::libmemcached::memcached_set($memcached, $key, $frozenValue, $ttl);
    if ($memcached->errstr eq 'SUCCESS') {
        return $value;
    }
    elsif ($memcached->errstr eq 'SYSTEM ERROR Unknown error: 0' || $retry) {
        confess "Cannot connect to memcached server.";
    }
    elsif ($memcached->errstr eq 'UNKNOWN READ FAILURE' ) {
        warn "Memcached went away, reconnecting.";
        $self->clear_memcached;
        return $self->set($namespace, $id, $value, $ttl, 1);
    }
    elsif ($memcached->errstr eq 'NO SERVERS DEFINED') {
        confess "No memcached servers specified.";
    }
    confess "Couldn't set $key to cache because ".$memcached->errstr;
}


no Moose;
__PACKAGE__->meta->make_immutable;

