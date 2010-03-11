use lib '../lib';
use Test::More tests => 9;
use Test::Deep;
use LWP::UserAgent;
use JSON qw(to_json from_json);
use Lacuna::DB;
use Config::JSON;
use Data::Dumper;
use 5.010;

my $result;
my $config = Config::JSON->new("/data/Lacuna-Server/etc/lacuna.conf");
my $db = Lacuna::DB->new( access_key => $config->get('access_key'), secret_key => $config->get('secret_key'), cache_servers => $config->get('memcached'));

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
my $last_energy = $result->{result}{status}{empire}{planets}{$home_planet}{energy_stored};
my $empire_id = $result->{result}{status}{empire}{id};

$result = post('/wheat', 'build', [$session_id, $home_planet, 3, 3]);
is($result->{result}{building}{name}, 'Wheat Farm', 'Can build buildings');
is($result->{result}{building}{level}, 0, 'New building is level 0');
cmp_ok($result->{result}{building}{pending_build}{seconds_remaining}, '>', 0, 'Building has time in queue');
cmp_ok($last_energy, '>', $result->{result}{status}{empire}{planets}{$home_planet}{energy_stored}, 'Resources are being spent.');

my $building = $db->domain('food')->find($result->{result}{building}{id});
$building->finish_upgrade;

$result = post('/wheat', 'view', [$session_id, $building->id]);
is($result->{result}{building}{level}, 1, 'New building is built');
ok(! exists $result->{result}{building}{pending_build}, 'Building is no longer in build queue');
$last_energy = $result->{result}{status}{empire}{planets}{$home_planet}{energy_stored};

my $empire = $db->domain('empire')->find($empire_id);
$empire->university_level(5);
$empire->put;

$result = post('/wheat', 'upgrade', [$session_id, $building->id]);
is($result->{result}{building}{level}, 1, 'Upgrading building is still level 1');
cmp_ok($result->{result}{building}{pending_build}{seconds_remaining}, '>', 0, 'Upgrade has time in queue');
cmp_ok($last_energy, '>', $result->{result}{status}{empire}{planets}{$home_planet}{energy_stored}, 'Resources are being spent for upgrade.');


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
    my $response = $ua->post($config->get('server_url').$url,
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
