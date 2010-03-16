use lib '../lib';
use Test::More tests => 10;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;

use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;
my $command = $home->command;

say "EMPIRE: ".$empire->id;
say "HOME PLANET: ".$home->id;

my $result;

$result = $tester->post('waterpurification', 'build', [$session_id, $home->id, 0, -5]);
ok($result->{result}{building}{id}, "built water purification");
sleep 853;

$result = $tester->post('mine', 'build', [$session_id, $home->id, 0, -4]);
ok($result->{result}{building}{id}, "built mine");
sleep 1003;

$result = $tester->post('hydrocarbon', 'build', [$session_id, $home->id, 0, -3]);
ok($result->{result}{building}{id}, "built hydrocarbon power plant");
sleep 703;

$result = $tester->post('corn', 'build', [$session_id, $home->id, 0, -2]);
ok($result->{result}{building}{id}, "built corn farm");
sleep 603;

$result = $tester->post('university', 'build', [$session_id, $home->id, 0, -1]);
ok($result->{result}{building}{id}, "built university");
sleep 1303;

$result = $tester->post('orestorage', 'build', [$session_id, $home->id, 0, 1]);
ok($result->{result}{building}{id}, "built ore storage tanks");
sleep 303;

$result = $tester->post('energyreserve', 'build', [$session_id, $home->id, 0, 2]);
ok($result->{result}{building}{id}, "built energy reserve");
sleep 1203;

$result = $tester->post('waterproduction', 'build', [$session_id, $home->id, 0, 3]);
ok($result->{result}{building}{id}, "built water production");
sleep 1153;

$result = $tester->post('waterstorage', 'build', [$session_id, $home->id, 0, 4]);
ok($result->{result}{building}{id}, "built water storage");
sleep 1003;

$result = $tester->post('foodreserve', 'build', [$session_id, $home->id, 0, 5]);
ok($result->{result}{building}{id}, "built food reserve");
sleep 1003;


END {
    $tester->cleanup;
}
