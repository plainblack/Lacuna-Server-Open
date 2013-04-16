package WWW::Firebase::TokenGenerate;

use Moose;
use JSON;
use JSON::WebToken;
use DateTime;
use Data::Dumper;

has 'secret' => (
    is          => 'rw',
    isa         => 'Str',
);

has 'version' => (
    is          => 'ro',
    isa         => 'Int',
    default     => 0,
);

has 'data' => (
    is          => 'rw',
);

has 'expires' => (
    is          => 'rw',
    isa         => 'Maybe[DateTime]',
);

has 'not_before' => (
    is          => 'rw',
    isa         => 'Maybe[DateTime]',
);

has 'debug' => (
    is          => 'rw',
    isa         => 'Maybe[Int]',
);

has 'admin' => (
    is          => 'rw',
    isa         => 'Maybe[Int]',
);

has 'algorithm' => (
    is          => 'rw',
    isa         => 'Str',
    default     => 'HS256',
);

sub create_token {
    my ($self, $data) = @_;

    $self->data($data) if defined $data;

    # ensure that data is JSONifiable
    my $json = encode_json($self->data);

    my $claims = {
        d       => $self->data,
        v       => $self->version,
        iat     => time,
    };
    $claims->{admin}    = $self->admin if $self->admin;
    $claims->{debug}    = $self->debug if $self->debug;
    $claims->{nbf}      = $self->not_before->epoch if defined $self->not_before;
    $claims->{exp}      = $self->expires->epoch if defined $self->expires;

print STDERR "Claims: ".Dumper(\$claims);

    my $jwt = encode_jwt($claims, $self->secret, $self->algorithm);

}


1;


