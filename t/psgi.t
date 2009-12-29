use lib '../lib';
use Test::More tests => 17;
use Test::Deep;
use LWP::UserAgent;
use JSON qw(to_json from_json);
use Lacuna::DB;
use Data::Dumper;
use 5.010;

my $result;

### SPECIES
$result = post('species', {method=>'is_name_available', params=>['Human']});
is($result->{result}, 0, 'species name not available');

$result = post('species', {method=>'is_name_available', params=>['Borg']});
is($result->{result}, 1, 'species name is available');

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

$result = post('species', {method=>'create', params=>$borg});
is($result->{error}{code}, 1000, 'create species with an existing name');

$borg->{name} = 'Borg abcdefghijklmnopqrstuvwxyz 123456';
$result = post('species', {method=>'create', params=>$borg});
is($result->{error}{code}, 1000, 'create species with too long a name');

$borg->{name} = 'Borg >';
$result = post('species', {method=>'create', params=>$borg});
is($result->{error}{code}, 1000, 'create species with invalid characters in the name');

$borg->{name} = '';
$result = post('species', {method=>'create', params=>$borg});
is($result->{error}{code}, 1000, 'create species with no name');

$borg->{name} = 'Borg';
$borg->{description} = 'cyborg &';
$result = post('species', {method=>'create', params=>$borg});
is($result->{error}{code}, 1005, 'create species with junk in description');

$borg->{description} = 'cyborg';
push @{$borg->{habitable_orbits}}, 8;
$result = post('species', {method=>'create', params=>$borg});
is($result->{error}{code}, 1007, 'create species with too many orbits');

$borg->{habitable_orbits} = [];
$result = post('species', {method=>'create', params=>$borg});
is($result->{error}{code}, 1008, 'create species with too few orbits');

$borg->{habitable_orbits} = 'blah';
$result = post('species', {method=>'create', params=>$borg});
is($result->{error}{code}, -32603, 'create species with a non-array of orbits');

$borg->{habitable_orbits} = [0];
$result = post('species', {method=>'create', params=>$borg});
is($result->{error}{code}, 1009, 'create species with invalid orbits');

$borg->{habitable_orbits} = ['foo'];
$result = post('species', {method=>'create', params=>$borg});
is($result->{error}{code}, 1009, 'create species with invalid orbits 2');

$borg->{habitable_orbits} = [1,2,3,4,5,6,7];
$borg->{research_affinity} = 8;
$result = post('species', {method=>'create', params=>$borg});
is($result->{error}{code}, 1007, 'affinity too high');

$borg->{research_affinity} = 0;
$result = post('species', {method=>'create', params=>$borg});
is($result->{error}{code}, 1008, 'affinity too low');

$borg->{research_affinity} = 1;
$result = post('species', {method=>'create', params=>$borg});
is($result->{error}{code}, 1008, 'too few points spent');

$borg->{research_affinity} = 5;
$result = post('species', {method=>'create', params=>$borg});
is($result->{error}{code}, 1007, 'too many points spent');

$borg->{research_affinity} = 4;
$result = post('species', {method=>'create', params=>$borg});
cmp_deeply(
    $result,
    {jsonrpc=>'2.0', id=>1, result=>ignore()},
    'create species'
);
my $borg_id = $result->{result};

### MAP
#{method=>"get_stars",params=>["xxx",-3,-3,2,2,0]}



sub post {
    my $url = shift;
    my $content = shift;
    $content->{jsonrpc} = '2.0';
    $content->{id} = 1;
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
    $db->domain('species')->find($borg_id)->delete;
}
