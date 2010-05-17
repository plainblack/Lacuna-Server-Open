use lib '../lib';
use Test::More tests => 10;
use Test::Deep;
use Data::Dumper;
use 5.010;

use TestHelper;
my $tester = TestHelper->new->generate_test_empire->build_infrastructure;
my $db = Lacuna->db;
my $session_id = $tester->session->id;
my $empire_id = $tester->empire->id;

my $result;
my $university = $db->resultset('Lacuna::DB::Result::Building')->search({class=>'Lacuna::DB::Result::Building::University', body_id=>$tester->empire->home_planet_id})->single;
my $uid = $university->id;

$result = $tester->post('university', 'view', [$session_id, $uid]);
is($result->{result}{building}{level}, 6, "made it to level 6");
my $empire = $db->resultset('Lacuna::DB::Result::Empire')->find($empire_id);
is($empire->university_level, 6, 'empire university level was upgraded');

for my $level (7..10) {

    $result = $tester->post('university', 'upgrade', [$session_id, $uid]);    
    $db->resultset('Lacuna::DB::Result::Building')->find($uid)->finish_upgrade;
    Lacuna->cache->delete('upgrade_contention_lock', $uid);
    
    $result = $tester->post('university', 'view', [$session_id, $uid]);
    is($result->{result}{building}{level}, $level, "made it to level ".$level);
    $empire = $db->resultset('Lacuna::DB::Result::Empire')->find($empire_id);
    is($empire->university_level, $level, 'empire university level was upgraded');    
}


END {
    $tester->cleanup;
}
