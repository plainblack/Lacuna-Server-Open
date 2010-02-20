use lib '../lib';
use Test::More tests => 9;
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
my $current_planet = $result->{result}{status}{empire}{current_planet_id};
my $last_energy = $result->{result}{status}{empire}{planets}{$current_planet}{energy_stored};

$result = post('/wheat', 'build', [$session_id, $current_planet, 3, 3]);
is($result->{result}{building}{name}, 'Wheat Farm', 'Can build buildings');
is($result->{result}{building}{level}, 0, 'New building is level 0');
cmp_ok($result->{result}{building}{time_left_on_build}, '>', 0, 'Building has time in queue');
cmp_ok($last_energy, '>', $result->{result}{status}{empire}{planets}{$current_planet}{energy_stored}, 'Resources are being spent.');

my $building = $db->domain('food')->find($result->{result}{building}{id});
$building->finish_upgrade;

$result = post('/wheat', 'view', [$session_id, $building->id]);
is($result->{result}{building}{level}, 1, 'New building is built');
is($result->{result}{building}{time_left_on_build}, 0, 'Building is no longer in build queue');
$last_energy = $result->{result}{status}{empire}{planets}{$current_planet}{energy_stored};

$result = post('/wheat', 'upgrade', [$session_id, $building->id]);
is($result->{result}{building}{level}, 1, 'Upgrading building is still level 1');
cmp_ok($result->{result}{building}{time_left_on_build}, '>', 0, 'Upgrade has time in queue');
cmp_ok($last_energy, '>', $result->{result}{status}{empire}{planets}{$current_planet}{energy_stored}, 'Resources are being spent for upgrade.');


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
    #say "REQUEST: ".to_json($content);
    my $response = $ua->post('http://localhost:5000/'.$url,
        Content_Type    => 'application/json',
        Content         => to_json($content),
        Accept          => 'application/json',
        );
    #say "RESPONSE: ".$response->content;
    return from_json($response->content);
}

END {
    $db->domain('empire')->find($fed_id)->delete;
    $db->domain('session')->find($session_id)->delete;
}
