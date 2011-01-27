package Lacuna::JRC;

use Moose;
use utf8;
no warnings qw(uninitialized);
use LWP::UserAgent;
use JSON qw(to_json from_json);
use Time::HiRes qw(usleep);

has ua => (
    is  => 'ro',
    lazy => 1,
    default => sub {  my $ua = LWP::UserAgent->new; $ua->timeout(30); return $ua; },
);


sub post {
    my ($self, $url, $method, $params) = @_;
    my $content = {
        jsonrpc     => '2.0',
        id          => 1,
        method      => $method,
        params      => $params,
    };
    my $response;
    foreach my $retry (1..5) {
        $response = $self->ua->post($url,
            Content_Type    => 'application/json',
            Content         => to_json($content),
            Accept          => 'application/json',
            );
        last if ($response->header('Content-Type') eq 'application/json-rpc');
        usleep((4 ** $retry) * 100_000);
    }
    confess [$response->code, 'Could not connect to JSON RPC server.'] unless ($response->header('Content-Type') eq 'application/json-rpc');
    my $result = from_json($response->content);
    if (exists $result->{error}) {
        confess [$result->{error}{code}, $result->{error}{message}, $result->{error}{data}];
    }
    return $result->{result};
}


no Moose;
__PACKAGE__->meta->make_immutable;
