package Lacuna::Session;

use Moose;
use UUID::Tiny;


has id => (
    is      => 'ro',
    default => sub {
        return create_UUID_as_string(UUID_V4);
    },
);

sub BUILD {
    my $self = shift;
    my $session_data = Lacuna->cache->get_and_deserialize('session', $self->id);
    if (defined $session_data) {
        $self->api_key($session_data->{api_key});
        $self->empire_id($session_data->{empire_id});
        $self->extended($session_data->{extended});
    }
}

has extended => (
    is          => 'rw',
    default     => 0,
);

has api_key => (
    is          => 'rw',
);

has empire_id => (
    is          => 'rw',
    predicate   => 'has_empire_id',
    trigger     => sub {
        my $self = shift;
        $self->clear_empire;
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
        my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($self->empire_id);
        if (defined $empire) {
            $empire->current_session($self);
        }
        return $empire;
    },
);

sub extend {
    my $self = shift;
    $self->extended( $self->extended + 1 );
    Lacuna->cache->set(
        'session',
        $self->id,
        { empire_id => $self->empire_id, api_key => $self->api_key, extended => $self->extended },
        60 * 60 * 2,
    );
    return $self;
}

sub end {
    my $self = shift;
    Lacuna->db->resultset('Lacuna::DB::Result::Log::Login')->search({
        session_id      => $self->id,
        log_out_date    => undef,
    })->update({
        log_out_date    => DateTime->now,
        extended        => $self->extended,
    });
    Lacuna->cache->delete('session', $self->id);
    return $self;
}

sub start {
    my ($self, $empire, $api_key) = @_;
    $self->empire_id($empire->id);
    $self->api_key($api_key);
    $empire->current_session($self);
    $self->empire($empire);
    Lacuna->db->resultset('Lacuna::DB::Result::Log::Login')->new({
        empire_id       => $empire->id,
        empire_name     => $empire->name,
        api_key      => $api_key,
        session_id      => $self->id,
    })->insert;
    return $self->extend;
}

no Moose;
__PACKAGE__->meta->make_immutable;
