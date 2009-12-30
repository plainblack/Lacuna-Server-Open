use lib '../lib';
use Test::More tests => 1;
use Test::Deep;
use LWP::UserAgent;
use JSON qw(to_json from_json);
use Lacuna::DB;
use Data::Dumper;
use 5.010;

my $result;

my $fed = {
    name        => 'The Federation',
    species_id  => 'human_species',
    password    => '123qwe',
    password1   => '123qwe',
};
$result = post('empire', 'create', $fed);
my $fed_id = $result->{result}{empire_id};
my $session_id = $result->{result}{session_id};

#{method=>"get_stars",params=>["xxx",-3,-3,2,2,0]}



sub post {
    my ($url, $method, $params) = @_;
    my $content = {
        jsonrpc     => '2.0',
        id          => 1,
        method      => $method,
        params      => $params,
    };
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    my $response = $ua->post('http://localhost:5000/'.$url,
        Content_Type    => 'application/json',
        Content         => to_json($content),
        Accept          => 'application/json',
        );
    return from_json($response->content);
}

END {
    my $db = Lacuna::DB->new(access_key => $ENV{SIMPLEDB_ACCESS_KEY}, secret_key => $ENV{SIMPLEDB_SECRET_KEY}, cache_servers => [{host=>'127.0.0.1', port=>11211}]);
    $db->domain('empire')->find($fed_id)->delete;
    $db->domain('session')->find($session_id)->delete;
}
