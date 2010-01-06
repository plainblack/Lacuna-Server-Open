use lib '../lib';
use Test::More tests => 10;
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
say Dumper $result;
my $fed_id = $result->{result}{empire_id};
my $session_id = $result->{result}{session_id};
my $current_planet = $result->{result}{status}{empire}{current_planet_id};

$result = post('map','get_stars_near_planet', [$session_id, $current_planet]);
say Dumper $result;
is(ref $result->{result}{stars}, 'ARRAY', 'get_stars_near_planet');
cmp_ok(scalar(@{$result->{result}{stars}}), '>', 0, 'get_stars_near_planet count');

$result = post('map','get_star_for_planet', [ $session_id, $current_planet]);
say Dumper $result;
is($result->{result}{star}{can_rename}, 1, 'get_star_for_planet');
my $star_id = $result->{result}{star}{id};

$result = post('map','rename_star', [$session_id, $star_id, 'some rand '.rand(9999999)]);
say Dumper $result;
is($result->{result}, 1, 'rename_star');

$result = post('map','rename_star', [$session_id, $star_id, 'new name']);
say Dumper $result;
is($result->{error}{code}, 1010, 'star has already been renamed');

$result = post('map','get_stars',[$session_id, -3,-3,2,2,0]);
is(ref $result->{result}{stars}, 'ARRAY', 'get stars');
cmp_ok(scalar(@{$result->{result}{stars}}), '>', 0, 'get stars count');

$result = post('map','rename_star', [$session_id, $result->{result}{stars}[0]{id}, 'new name']);
is($result->{error}{code}, 1010, 'no privilege to rename');

$result = post('map','rename_star', [$session_id, 'aaa', 'new name']);
is($result->{error}{code}, 1002, 'cannot rename non-existant star');

$result = post('map','get_stars',[$session_id, -30,-30,30,30,0]);
is($result->{error}{code}, 1003, 'get stars too big');




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
