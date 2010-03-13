package TestHelper;

use Moose;
use Config::JSON;
use Lacuna::DB;
use LWP::UserAgent;
use JSON qw(to_json from_json);
use Data::Dumper;
use 5.010;



has config => (
    is  => 'ro',
    lazy => 1,
    default => sub { Config::JSON->new("/data/Lacuna-Server/etc/lacuna.conf")},
);

has ua => (
    is  => 'ro',
    lazy => 1,
    default => sub {  my $ua = LWP::UserAgent->new; $ua->timeout(30); return $ua; },
);

has db => (
    is => 'ro',
    lazy => 1,
    default => sub {my $self = shift; return Lacuna::DB->new( access_key => $self->config->get('access_key'), secret_key => $self->config->get('secret_key'), cache_servers => $self->config->get('memcached')); },
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
    default => sub { my $self = shift; return $self->db->domain('empire')->search(where=>{name=>$self->empire_name}, consistent=>1)->next; },
);

has session => (
    is => 'rw',
);

sub generate_test_empire {
    my $self = shift;
    my $empire = Lacuna::DB::Empire->create($self->db, {name=>$self->empire_name, password=>$self->empire_password});
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
    my $empire = $self->empire;
    if (defined $empire) {
        say "Found the test empire.";
        $empire->delete;
        say "Deleted it.";
    }
    else {
        say "Couldn't find empire.";
    }
}


1;