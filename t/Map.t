use lib '../lib';
use Test::More tests => 15;
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
my $home_planet = $result->{result}{status}{empire}{home_planet_id};

$result = post('map','get_stars_near_body', [$session_id, $home_planet]);
is(ref $result->{result}{stars}, 'ARRAY', 'get_stars_near_body');
cmp_ok(scalar(@{$result->{result}{stars}}), '>', 0, 'get_stars_near_body count');

$result = post('map','get_star_by_body', [ $session_id, $home_planet]);
is($result->{result}{star}{can_rename}, 1, 'get_star_by_body');
my $star_id = $result->{result}{star}{id};

$result = post('map','rename_star', [$session_id, $star_id, 'some rand '.rand(9999999)]);
is($result->{result}, 1, 'rename_star');

$result = post('map','rename_star', [$session_id, $star_id, 'new name']);
is($result->{error}{code}, 1010, 'star has already been renamed');

$result = post('map','get_stars',[$session_id, -3,-3,2,2,0]);
is(ref $result->{result}{stars}, 'ARRAY', 'get stars');
cmp_ok(scalar(@{$result->{result}{stars}}), '>', 0, 'get stars count');
my $other_star = $result->{result}{stars}[0]{id};

$result = post('map','rename_star', [$session_id, $other_star, 'new name']);
is($result->{error}{code}, 1010, 'no privilege to rename');

$result = post('map','rename_star', [$session_id, 'aaa', 'new name']);
is($result->{error}{code}, 1002, 'cannot rename non-existant star');

$result = post('map','get_stars',[$session_id, -30,-30,30,30,0]);
is($result->{error}{code}, 1003, 'get stars too big');

$result = post('map','get_star_system', [$session_id, 'aaa']);
is($result->{error}{code}, 1002, 'get star system non-existant star');

$result = post('map','get_star_system', [$session_id, $other_star]);
is($result->{error}{code}, 1010, 'get star system no privilege');

$result = post('map','get_star_system', [$session_id, $star_id]);
is($result->{result}{star}{id},$star_id, 'get star system');

$result = post('map','get_star_system_by_body', [$session_id, $home_planet]);
is($result->{result}{star}{id},$star_id, 'get star system by body');

$result = post('map','get_star_system_by_body', [$session_id, 'aaa']);
is($result->{error}{code}, 1002, 'get star system by body non-existant body');




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
    my $db = Lacuna::DB->new(access_key => $ENV{SIMPLEDB_ACCESS_KEY}, secret_key => $ENV{SIMPLEDB_SECRET_KEY}, cache_servers => [{host=>'127.0.0.1', port=>11211}]);
    $db->domain('empire')->find($fed_id)->delete;
}
