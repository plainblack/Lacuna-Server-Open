package WWW::Firebase::API::Connection;

use MooseX::Singleton;

use Log::Log4perl;
use Data::Dumper;
use LWP::UserAgent;
use JSON;
use Carp;

has 'base_uri'          => (is => 'ro', required => 1);
has 'auth'              => (is => 'rw', required => 1);
has 'user_agent'        => (is => 'ro', lazy_build => 1);
has 'log'               => (is => 'ro', lazy_build => 1);

sub _build_log {
    my ($self) = @_;

    return Log::Log4perl->get_logger('WWW::Firebase::API::Connection');
}

sub _build_user_agent {
    my ($self) = @_;

    return LWP::UserAgent->new(env_proxy => 1);
}


sub GET {
    my ($self, $url, $params) = @_;

    return $self->call({
        url     => $url,
        method  => 'GET',
        params  => $params,
    });

}

sub POST {
    my ($self, $url, $data, $params) = @_;

    return $self->call({
        url     => $url,
        method  => 'POST',
        params  => $params,
        data    => $data,
    });
}

sub PUT {
    my ($self, $url, $data, $params) = @_;

    return $self->call({
        url     => $url,
        method  => 'PUT',
        params  => $params,
        data    => $data,
    });
}

sub DELETE {
    my ($self, $url, $params) = @_;

    return $self->call({
        url     => $url,
        method  => 'DELETE',
        params  => $params,
    });

}

sub call {
    my ($self, $args) = @_;

    my $url     = $args->{url};
    my $method  = $args->{method};
    my $data    = $args->{data};
    my $params  = $args->{params};

    if (defined $params) {
        $params .= "&auth=".$self->auth;
    }
    else {
        $params = "?auth=".$self->auth;
    }


    $self->log->debug("API-CALL: PATH $url : METHOD $method [$params]");

    $url = $self->base_uri.$url.'.json';
    $url .= "?$params" if $params;

    my $request = HTTP::Request->new($method => $url);
    $request->content(encode_json($data)) if $data;
    my $response = $self->user_agent->request($request);

    if (not $response->is_success) {
        Carp::croak("HTTP Error (".$response->status_line.")");
    }
    print STDERR "[".$response->content."]\n";
    return decode_json($response->content);
}

1;

