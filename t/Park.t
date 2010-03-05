use lib '../lib';
use Test::More tests => 4;
use Test::Deep;
use LWP::UserAgent;
use JSON qw(to_json from_json);
use Lacuna::DB;
use Data::Dumper;
use 5.010;

my $result;
my $db = Lacuna::DB->new(access_key => $ENV{SIMPLEDB_ACCESS_KEY}, secret_key => $ENV{SIMPLEDB_SECRET_KEY}, cache_servers => [{host=>'127.0.0.1', port=>11211}]);

my $fed = {
    name        => 'some rand'.rand(9999999),
    species_id  => 'human_species',
    password    => '123qwe',
    password1   => '123qwe',
};
$result = post('empire', 'create', $fed);
my $fed_id = $result->{result}{empire_id};
my $session_id = $result->{result}{session_id};
my $home_planet = $result->{result}{status}{empire}{home_planet_id};
my $empire_id = $result->{result}{status}{empire}{id};

$result = post('park', 'build', [$session_id, $home_planet, 3, 3]);

my $building = $db->domain('Lacuna::DB::Building::Park')->find($result->{result}{building}{id});
$building->finish_upgrade;

$result = post('park', 'throw_a_party', [$session_id, $building->id]);

is($result->{error}{code}, 1011, "can't throw a party without food");

my $body = $building->body;
$body->algae_stored(20000);
$body->put;

$result = post('park', 'throw_a_party', [$session_id, $building->id]);
cmp_ok($result->{result}{status}{planets}[0]{food_stored}, '<', 20_000, "food gets spent");
cmp_ok($result->{result}{party}{seconds_remaining}, '>', 0, "timer is started");
my $happy = $result->{result}{status}{planets}[0]{happiness};

my $building = $db->domain('Lacuna::DB::Building::Park')->find($result->{result}{building}{id});
$building->end_the_party;
cmp_ok($result->{result}{status}{planets}[0]{happiness}, '<', $building->body->happiness, "happiness is increased");


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
    say "REQUEST: ".to_json($content);
    my $response = $ua->post('http://localhost:5000/'.$url,
        Content_Type    => 'application/json',
        Content         => to_json($content),
        Accept          => 'application/json',
        );
    say "RESPONSE: ".$response->content;
    return from_json($response->content);
}

END {
    $db->domain('empire')->find($fed_id)->delete;
}
