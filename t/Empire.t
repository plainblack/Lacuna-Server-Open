use lib '../lib';
use Test::More tests => 12;
use Test::Deep;
use LWP::UserAgent;
use JSON qw(to_json from_json);
use Lacuna::DB;
use Data::Dumper;
use 5.010;

my $result;

cleanup();

my $config = Config::JSON->new("/data/Lacuna-Server/etc/lacuna.conf");

$result = post('empire', 'is_name_available', ['The Federation']);
is($result->{result}, 1, 'empire name is available');

my $fed = {
    name        => 'The Federation',
    species_id  => 'human_species',
    password    => '123qwe',
    password1   => '123qwe',
};

$fed->{name} = 'XX>';
$result = post('empire', 'create', $fed);
is($result->{error}{code}, 1000, 'empire name has funky chars');

$fed->{name} = '';
$result = post('empire', 'create', $fed);
is($result->{error}{code}, 1000, 'empire name too short');

$fed->{name} = 'abc def ghi jkl mno pqr stu vwx yz 0123456789';
$result = post('empire', 'create', $fed);
is($result->{error}{code}, 1000, 'empire name too long');

$fed->{name} = 'The Federation';
$fed->{password} = 'abc';
$result = post('empire', 'create', $fed);
is($result->{error}{code}, 1001, 'empire password too short');

$fed->{password} = 'abc123';
$result = post('empire', 'create', $fed);
is($result->{error}{code}, 1001, 'empire passwords do not match');

$fed->{password} = '123qwe';
$fed->{species_id} = 'xxx';
$result = post('empire', 'create', $fed);
is($result->{error}{code}, 1002, 'empire species does not exist');

$fed->{species_id} = 'human_species';
$result = post('empire', 'create', $fed);
ok(exists $result->{result}{empire_id}, 'empire created');
ok(exists $result->{result}{session_id}, 'empire logged in after creation');
my $fed_id = $result->{result}{empire_id};
my $session_id = $result->{result}{session_id};

$result = post('empire', 'is_name_available', ['The Federation']);
is($result->{result}, 0, 'empire name not available');

$result = post('empire', 'logout', [$session_id]);
is($result->{result}, 1, 'logout');

$result = post('empire', 'login', ['the Federation','123qwe']);
ok(exists $result->{result}{session_id}, 'login');
$session_id = $result->{result}{session_id};






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
    say "REQUEST: " .to_json($content);
    my $response = $ua->post($config->get('server_url').$url,
        Content_Type    => 'application/json',
        Content         => to_json($content),
        Accept          => 'application/json',
        );
    say "RESPONSE: ".$response->content;
    return from_json($response->content);
}

sub cleanup {
    my $db = Lacuna::DB->new( access_key => $config->get('access_key'), secret_key => $config->get('secret_key'), cache_servers => $config->get('memcached'));
    my $empire = $db->domain('empire')->search(where=>{name=>'The Federation'})->next;
    if (defined $empire) {
        say "Found empire";
        $empire->delete;
    }
    else {
        say "Couldn't find empire.";
    }
}

END {
    cleanup();
}
