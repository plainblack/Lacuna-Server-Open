use lib '../lib';
use Test::More tests => 3;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;

use TestHelper;
TestHelper->clear_all_test_empires;

my $tester = TestHelper->new->generate_test_empire->build_infrastructure;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;

my $result;

$result = $tester->post('missioncommand', 'build', [$session_id, $home->id, 0, 3]);
ok($result->{result}{building}{id}, "built a mission command");
my $mc = $tester->get_building($result->{result}{building}{id});
$mc->finish_upgrade;


$result = $tester->post('missioncommand', 'get_missions', [$session_id, $mc->id]);
ok(exists $result->{result}, 'can call get_missions');

$result = $tester->post('missioncommand', 'complete_mission', [$session_id, $mc->id, 'noexistid']);
is($result->{error}{code}, 1002, 'can call complete_mission');

END {
    TestHelper->clear_all_test_empires;
}
