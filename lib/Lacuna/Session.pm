package Lacuna::Session;

use Moose;
use UUID::Tiny ':std';


has id => (
    is      => 'ro',
    default => sub {
        return create_UUID_as_string(UUID_V4);
    },
);

has empire_id => (
    is          => 'rw',
    predicate   => 'has_empire_id',
    lazy        => 1,
    trigger     => sub {
        my $self = shift;
        $self->clear_empire;
    },
    default     => sub {
        my $self = shift;
        return Lacuna->cache->get('session', $self->id);
    },
);

has empire => (
    is          => 'rw',
    predicate   => 'has_empire',
    clearer     => 'clear_empire',
    lazy        => 1,
    default     => sub {
        my $self = shift;
        return undef unless $self->has_empire_id;
        return Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($self->empire_id);
    },
);

sub extend {
    my $self = shift;
    Lacuna->cache->set('session', $self->id, $self->empire_id, 60 * 60 * 2);
    return $self;
}

sub end {
    my $self = shift;
    Lacuna->cache->delete('session', $self->id);
    return $self;
}

sub start {
    my ($self, $empire) = @_;
    $self->empire_id($empire->id);
    return $self->extend;
}

no Moose;
__PACKAGE__->meta->make_immutable;
