use lib '../lib';
use Test::More tests => 3;
use Test::Deep;
use Data::Dumper;
use 5.010;

use TestHelper;
TestHelper->clear_all_test_empires;

my $tester = TestHelper->new->generate_test_empire->build_infrastructure;
my $db = Lacuna->db;
my $empire = $tester->empire;
my $session_id = $tester->session->id;
my $home = $empire->home_planet;
my $result;

$result = $tester->post('wasterecycling', 'build', [$session_id, $home->id, 3, 3]);

my $building = $db->resultset('Lacuna::DB::Result::Building')->find($result->{result}{building}{id});
$building->finish_upgrade;

$result = $tester->post('wasterecycling', 'recycle', [$session_id, $building->id, 999990000,5,5]);

is($result->{error}{code}, 1011, "can't recycle with waste you don't have");

$home->waste_stored(500);
$home->waste_capacity(500);
$home->update;

$result = $tester->post('wasterecycling', 'recycle', [$session_id, $building->id, 5,5,5]);
cmp_ok($result->{result}{recycle}{seconds_remaining}, '>', 0, "timer is started");

my $water_stored = $building->body->water_stored;

$building = $db->resultset('Lacuna::DB::Result::Building')->find($building->id);
$building->finish_work;
cmp_ok($building->body->water_stored, '>=', $water_stored + 5, "resources increased");

END {
    TestHelper->clear_all_test_empires;
}
