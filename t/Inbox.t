use lib '../lib';
use Test::More tests => 8;
use Test::Deep;
use LWP::UserAgent;
use JSON qw(to_json from_json);
use Config::JSON;
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

$result = post('inbox','send_message', [$session_id, $fed->{name}.', Some Guy', 'my subject', 'my body']);
is($result->{result}{message}{sent}[0], $fed->{name}, 'send message works');
is($result->{result}{message}{unknown}[0], 'Some Guy', 'detecting unknown recipients works');

sleep 2;

$result = post('inbox','view_inbox', [$session_id]);
is($result->{result}{messages}[1]{subject}, 'my subject', 'view inbox works');
is($result->{result}{status}{empire}{has_new_messages}, 2, 'new message count works');
my $message_id = $result->{result}{messages}[1]{id};

$result = post('inbox', 'read_message', [$session_id, $message_id]);
is($result->{result}{message}{body}, 'my body', 'can view a message');

$result = post('inbox','view_sent', [$session_id]);
is($result->{result}{messages}[0]{subject}, 'my subject', 'view sent works');

$result = post('inbox', 'archive_messages', [$session_id, [$message_id]]);
is($result->{result}{success}, 1, 'archiving works');

sleep 1;

$result = post('inbox','view_archived', [$session_id]);
is($result->{result}{messages}[0]{subject}, 'my subject', 'view archived works');

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
