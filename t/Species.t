use lib '../lib';
use Test::More tests => 23;
use Test::Deep;
use Data::Dumper;
use 5.010;
$|=1;

use TestHelper;
my $tester = TestHelper->new;

cleanup(); # in case there were failed runs previously

my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->new({name=>$tester->empire_name})->insert;
$tester->empire($empire);
my $empire_id = $empire->id;


my $result;

$result = $tester->post('species', 'is_name_available', ['Human']);
is($result->{error}{code}, 1000, 'species name Human not available');

$result = $tester->post('species', 'is_name_available', ['Borg']);
is($result->{result}, 1, 'species name Borg is available');

my $borg = {
        name=>'Human', 
        description=>'cyborg', 
        habitable_orbits=>[1,2,3,4,5,6,7],
        manufacturing_affinity   => 7,
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

$result = $tester->post('species', 'create', [$empire_id, $borg]);
is($result->{error}{code}, 1000, 'create species with an existing name');

$borg->{name} = 'Borg abcdefghijklmnopqrstuvwxyz 123456';
$result = $tester->post('species', 'create', [$empire_id, $borg]);
is($result->{error}{code}, 1000, 'create species with too long a name');

$borg->{name} = 'Borg >';
$result = $tester->post('species', 'create', [$empire_id, $borg]);
is($result->{error}{code}, 1000, 'create species with invalid characters in the name');

$borg->{name} = '';
$result = $tester->post('species', 'create', [$empire_id, $borg]);
is($result->{error}{code}, 1000, 'create species with no name');

$borg->{name} = 'Borg';
$borg->{description} = 'cyborg &';
$result = $tester->post('species', 'create', [$empire_id, $borg]);
is($result->{error}{code}, 1005, 'create species with junk in description');

$borg->{description} = 'cyborg';
push @{$borg->{habitable_orbits}}, 8;
$result = $tester->post('species', 'create', [$empire_id, $borg]);
is($result->{error}{code}, 1007, 'create species with too many orbits');

$borg->{habitable_orbits} = [];
$result = $tester->post('species', 'create', [$empire_id, $borg]);
is($result->{error}{code}, 1008, 'create species with too few orbits');

$borg->{habitable_orbits} = 'blah';
$result = $tester->post('species', 'create', [$empire_id, $borg]);
is($result->{error}{code}, -32603, 'create species with a non-array of orbits');

$borg->{habitable_orbits} = [0];
$result = $tester->post('species', 'create', [$empire_id, $borg]);
is($result->{error}{code}, 1009, 'create species with invalid orbits');

$borg->{habitable_orbits} = ['foo'];
$result = $tester->post('species', 'create', [$empire_id, $borg]);
is($result->{error}{code}, 1009, 'create species with invalid orbits 2');

$borg->{habitable_orbits} = [1,2,3,4,5,6,7];
$borg->{research_affinity} = 8;
$result = $tester->post('species', 'create', [$empire_id, $borg]);
is($result->{error}{code}, 1007, 'affinity too high');

$borg->{research_affinity} = 0;
$result = $tester->post('species', 'create', [$empire_id, $borg]);
is($result->{error}{code}, 1008, 'affinity too low');

$borg->{research_affinity} = 1;
$result = $tester->post('species', 'create', [$empire_id, $borg]);
is($result->{error}{code}, 1008, 'too few points spent');

$borg->{research_affinity} = 5;
$result = $tester->post('species', 'create', [$empire_id, $borg]);
is($result->{error}{code}, 1007, 'too many points spent');

$borg->{research_affinity} = 4;
$result = $tester->post('species', 'create', [$empire_id, $borg]);
cmp_deeply(
    $result,
    {jsonrpc=>'2.0', id=>1, result=>ignore()},
    'create species'
);
my $borg_id = $result->{result};

$result = $tester->post('species', 'is_name_available', ['Borg']);
is($result->{error}{code}, 1000, 'species name Borg not available');

$result = $tester->post('species', 'create', [$empire_id, $borg]);
ok(exists $result->{result}, 're-create works');

$result = $tester->post('empire', 'found', [$empire_id]);

$empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($empire_id);
is($empire->species->name, 'Borg', 'species getting set properly');
is($empire->home_planet->command->level, 7, 'growth affinity works');

$tester->session($empire->start_session);
$result = $tester->post('species','view_stats',[$tester->session->id]);
is($result->{result}{species}{name}, 'Borg', 'get species name');
is($result->{result}{species}{research_affinity}, 4, 'get affinity');

sub cleanup {
    $tester->cleanup;
}

END {
    cleanup();
}
