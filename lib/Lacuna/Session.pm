package Lacuna::Session;

use Moose;
use utf8;
no warnings qw(uninitialized);
use UUID::Tiny ':std';
use Lacuna::Util qw(real_ip_address);

has id => (
    is      => 'ro',
    default => sub {
        return create_uuid_as_string(UUID_V4);
    },
);

sub BUILD {
    my $self = shift;
    my $session_data = Lacuna->cache->get_and_deserialize('session', $self->id);
    if (defined $session_data && ref $session_data eq 'HASH') {
        $self->api_key($session_data->{api_key});
        $self->empire_id($session_data->{empire_id});
        $self->extended($session_data->{extended});
        $self->is_sitter($session_data->{is_sitter});
        $self->is_from_admin($session_data->{is_from_admin});
        $self->ip_address($session_data->{ip_address});
    }
}

has extended => (
    is          => 'rw',
    default     => 0,
);

has api_key => (
    is          => 'rw',
);

has is_sitter => (
    is          => 'rw',
    default     => 0,
);

has is_from_admin => (
    is          => 'rw',
    default     => 0,
);

has empire_id => (
    is          => 'rw',
    predicate   => 'has_empire_id',
    trigger     => sub {
        my $self = shift;
        $self->clear_empire;
    },
);

has ip_address => (
    is      => 'rw',
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

sub check_captcha {
    my $self = shift;
    my $valid = Lacuna->cache->get('captcha_valid', $self->id);
    if ( defined $valid && $valid  ) {
        return 1;
    }
    confess [1016,'Needs to solve a captcha.'];
}

sub update {
    my $self = shift;
    Lacuna->cache->set(
        'session',
        $self->id,
        { 
            empire_id       => $self->empire_id,
            api_key         => $self->api_key,
            extended        => $self->extended,
            is_sitter       => $self->is_sitter,
            is_from_admin   => $self->is_from_admin,
            ip_address      => $self->ip_address,
        },
        60 * 60 * 2,
    );
}

sub extend {
    my $self = shift;
    $self->extended( $self->extended + 1 );
    $self->update;
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
    my ($self, $empire, $options) = @_;
    $self->empire_id($empire->id);
    $self->api_key($options->{api_key});
    $self->is_sitter($options->{is_sitter});
    $self->is_from_admin($options->{is_from_admin});
    $empire->current_session($self);
    $self->empire($empire);
    my $ip;
    if (exists $options->{request}) {
        $ip = real_ip_address($options->{request});
        $self->ip_address($ip);
    }
    Lacuna->db->resultset('Lacuna::DB::Result::Log::Login')->new({
        empire_id       => $empire->id,
        empire_name     => $empire->name,
        api_key         => $options->{api_key},
        ip_address      => $ip,
        session_id      => $self->id,
        is_sitter       => $options->{is_sitter} ? 1 : 0,
        # is_from_admin => $options->{is_from_admin} <-- probably not needed
    })->insert;
    return $self->extend;
}

no Moose;
__PACKAGE__->meta->make_immutable;
