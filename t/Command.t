use lib '../lib';
use Test::More tests => 1;
use Test::Deep;
use LWP::UserAgent;
use JSON qw(to_json from_json);
use Lacuna::DB;
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
my $empire_id = $result->{result}{status}{empire}{id};

$result = post('body','get_buildings', [$session_id, $home_planet]);

my $id;
foreach my $bid (keys %{$result->{result}{buildings}}) {
    if ($result->{result}{buildings}{$bid}{name} eq 'Planetary Command') {
        $id = $bid;
        last;
    }
}

$result = post('planetarycommand', 'view', [$session_id, $id]);

is($result->{result}{planet}{building_count}, 1, "got building count");

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
