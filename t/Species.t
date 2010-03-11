use lib '../lib';
use Test::More tests => 18;
use Test::Deep;
use LWP::UserAgent;
use Config::JSON;
use JSON qw(to_json from_json);
use Lacuna::DB;
use Data::Dumper;
use 5.010;
$|=1;

cleanup(); # in case there were failed runs previously

my $result;

$result = post('species', 'is_name_available', ['Human']);
is($result->{result}, 0, 'species name Human not available');

$result = post('species', 'is_name_available', ['Borg']);
is($result->{result}, 1, 'species name Borg is available');

my $borg = {
        name=>'Human', 
        description=>'cyborg', 
        habitable_orbits=>[1,2,3,4,5,6,7],
        construction_affinity   => 7,
        deception_affinity      => 1,
        research_affinity       => 4,
        management_affinity     => 7,
        farming_affinity        => 1,
        mining_affinity         => 1,
        science_affinity        => 7,
        environmental_affinity  => 1,
        political_affinity      => 1,
        trade_affinity          => 1,
        growth_affinity         => 7,
        };

$result = post('species', 'create', $borg);
is($result->{error}{code}, 1000, 'create species with an existing name');

$borg->{name} = 'Borg abcdefghijklmnopqrstuvwxyz 123456';
$result = post('species', 'create', $borg);
is($result->{error}{code}, 1000, 'create species with too long a name');

$borg->{name} = 'Borg >';
$result = post('species', 'create', $borg);
is($result->{error}{code}, 1000, 'create species with invalid characters in the name');

$borg->{name} = '';
$result = post('species', 'create', $borg);
is($result->{error}{code}, 1000, 'create species with no name');

$borg->{name} = 'Borg';
$borg->{description} = 'cyborg &';
$result = post('species', 'create', $borg);
is($result->{error}{code}, 1005, 'create species with junk in description');

$borg->{description} = 'cyborg';
push @{$borg->{habitable_orbits}}, 8;
$result = post('species', 'create', $borg);
is($result->{error}{code}, 1007, 'create species with too many orbits');

$borg->{habitable_orbits} = [];
$result = post('species', 'create', $borg);
is($result->{error}{code}, 1008, 'create species with too few orbits');

$borg->{habitable_orbits} = 'blah';
$result = post('species', 'create', $borg);
is($result->{error}{code}, -32603, 'create species with a non-array of orbits');

$borg->{habitable_orbits} = [0];
$result = post('species', 'create', $borg);
is($result->{error}{code}, 1009, 'create species with invalid orbits');

$borg->{habitable_orbits} = ['foo'];
$result = post('species', 'create', $borg);
is($result->{error}{code}, 1009, 'create species with invalid orbits 2');

$borg->{habitable_orbits} = [1,2,3,4,5,6,7];
$borg->{research_affinity} = 8;
$result = post('species', 'create', $borg);
is($result->{error}{code}, 1007, 'affinity too high');

$borg->{research_affinity} = 0;
$result = post('species', 'create', $borg);
is($result->{error}{code}, 1008, 'affinity too low');

$borg->{research_affinity} = 1;
$result = post('species', 'create', $borg);
is($result->{error}{code}, 1008, 'too few points spent');

$borg->{research_affinity} = 5;
$result = post('species', 'create', $borg);
is($result->{error}{code}, 1007, 'too many points spent');

$borg->{research_affinity} = 4;
$result = post('species', 'create', $borg);
cmp_deeply(
    $result,
    {jsonrpc=>'2.0', id=>1, result=>ignore()},
    'create species'
);
my $borg_id = $result->{result};

sleep 2; # give it a chance to populate
$result = post('species', 'is_name_available', ['Borg']);
is($result->{result}, 0, 'species name Borg not available');


my $config = Config::JSON->new("/data/Lacuna-Server/etc/lacuna.conf");
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
#    say "REQUEST: ".to_json($content);
    my $response = $ua->post($config->get('server_url').$url,
        Content_Type    => 'application/json',
        Content         => to_json($content),
        Accept          => 'application/json',
        );
#    say "RESPONSE: ".$response->content;
    return from_json($response->content);
}

sub cleanup {
my $db = Lacuna::DB->new( access_key => $config->get('access_key'), secret_key => $config->get('secret_key'), cache_servers => $config->get('memcached'));
    my $species = $db->domain('species');
    if (defined $species) {
        say "Locating borg";
        my $borg = eval {$species->search(where=>{name=>'Borg'})};
        if ($@) {
            die "WTF: ".$@;
        }
        elsif (defined $borg) {
            say "Deleting borg";
            $borg->delete;
            say "Borg deleted";
        }
        else {
            say "No borg found.";
        }
    }
    else {
        say "Couldn't acquire species domain.";
    }
}

END {
    cleanup();
}
