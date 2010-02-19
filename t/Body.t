use lib '../lib';
use Test::More tests => 7;
use Test::Deep;
use LWP::UserAgent;
use JSON qw(to_json from_json);
use Lacuna::DB;
use Data::Dumper;
use 5.010;

my $result;

my $fed = {
    name        => 'some rand'.rand(9999999),
    species_id  => 'human_species',
    password    => '123qwe',
    password1   => '123qwe',
};
$result = post('empire', 'create', $fed);
my $fed_id = $result->{result}{empire_id};
my $session_id = $result->{result}{session_id};
my $current_planet = $result->{result}{status}{empire}{current_planet_id};

$result = post('body','rename', [$session_id, $current_planet, 'some rand '.rand(9999999)]);
is($result->{result}, 1, 'rename');

$result = post('body','rename', [$session_id, $current_planet, 'way too fricken long to be a valid name']);
is($result->{error}{code}, 1000, 'bad name');

$result = post('body','rename', [$session_id, 'aaa', 'new name']);
is($result->{error}{code}, 1002, 'cannot rename non-existant planet');

$result = post('body','get_buildings', [$session_id, 'aaa']);
is($result->{error}{code}, 1002, 'cannot fetch buildings on non-existant planet');

$result = post('body','get_buildings', [$session_id, $current_planet]);
is(ref $result->{result}{buildings}, 'HASH', 'fetch building list');
my $id;
foreach my $key (keys %{$result->{result}{buildings}}) {
    if ($result->{result}{buildings}{$key}{name} eq 'Planetary Command') {
        $id = $key;
        last;
    }
}
ok($result->{result}{buildings}{$id}{name} ne '', 'building has a name');

my $url = $result->{result}{buildings}{$id}{url};
$url =~ s/\///;
$result = post($url, 'view', [$session_id, $id]);
ok($result->{result}{building}{energy_hour} > 0, 'command center is functional');


sub post {
    my ($url, $method, $params) = @_;
    my $content = {
        jsonrpc     => '2.0',
        id          => 1,
        method      => $method,
        params      => $params,
    };
    my $ua = LWP::UserAgent->new;
    $ua->timeout(30);
#    say "REQUEST: ".to_json($content);
    my $response = $ua->post('http://localhost:5000/'.$url,
        Content_Type    => 'application/json',
        Content         => to_json($content),
        Accept          => 'application/json',
        );
#    say "RESPONSE: ".$response->content;
    return from_json($response->content);
}

END {
    my $db = Lacuna::DB->new(access_key => $ENV{SIMPLEDB_ACCESS_KEY}, secret_key => $ENV{SIMPLEDB_SECRET_KEY}, cache_servers => [{host=>'127.0.0.1', port=>11211}]);
    $db->domain('empire')->find($fed_id)->delete;
    $db->domain('session')->find($session_id)->delete;
}
