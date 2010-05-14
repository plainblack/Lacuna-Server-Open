package TestHelper;

use Moose;
use Lacuna::DB;
use Lacuna;
use LWP::UserAgent;
use JSON qw(to_json from_json);
use Data::Dumper;
use 5.010;



has config => (
    is  => 'ro',
    lazy => 1,
    default => sub { Lacuna->config },
);

has ua => (
    is  => 'ro',
    lazy => 1,
    default => sub {  my $ua = LWP::UserAgent->new; $ua->timeout(30); return $ua; },
);

has db => (
    is => 'ro',
    lazy => 1,
    default => sub {return Lacuna->db; },
);

has empire_name => (
    is => 'ro',
    default => 'TLE Test Empire',
);

has empire_password => (
    is => 'ro',
    default => '123qwe',
);

has empire => (
    is  => 'rw',
    lazy => 1,
    default => sub { my $self = shift; return $self->db->resultset('Lacuna::DB::Result::Empire')->search({name=>$self->empire_name})->single; },
);

has session => (
    is => 'rw',
);

sub generate_test_empire {
    my $self = shift;
    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->new({
        name                => $self->empire_name,
        date_created        => DateTime->now,
        species_id          => 2,
        status_message      => 'Making Lacuna a better Expanse.',
        password            => Lacuna::DB::Result::Empire->encrypt_password($self->empire_password),

    })->insert;
    $empire->found;
    $self->session($empire->start_session);
    $self->empire($empire);
    return $self;
}

sub post {
    my ($self, $url, $method, $params) = @_;
    my $content = {
        jsonrpc     => '2.0',
        id          => 1,
        method      => $method,
        params      => $params,
    };
    say "REQUEST: ".to_json($content);
    my $response = $self->ua->post($self->config->get('server_url').$url,
        Content_Type    => 'application/json',
        Content         => to_json($content),
        Accept          => 'application/json',
        );
    say "RESPONSE: ".$response->content;
    return from_json($response->content);
}

sub cleanup {
    my $self = shift;
    my $empires = $self->db->resultset('Lacuna::DB::Result::Empire')->search({name=>$self->empire_name});
    while (my $empire = $empires->next) {
        say "Found a test empire.";
        $empire->delete;
        say "Deleted it.";
    }
}


1;
