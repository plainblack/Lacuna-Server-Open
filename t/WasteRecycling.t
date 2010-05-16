use lib '../lib';
use Test::More tests => 3;
use Test::Deep;
use Data::Dumper;
use 5.010;

use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $db = Lacuna->db;
my $empire = $tester->empire;
my $session_id = $tester->session->id;
my $home = $empire->home_planet;

my $result;

my $uni = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => -1,
    class           => 'Lacuna::DB::Result::Building::University',
    level           => 2,
});
$home->build_building($uni);
$uni->finish_upgrade;

$home->ore_capacity(5000);
$home->energy_capacity(5000);
$home->food_capacity(5000);
$home->water_capacity(5000);
$home->bauxite_stored(5000);
$home->algae_stored(5000);
$home->energy_stored(5000);
$home->water_stored(5000);
$home->energy_hour(5000);
$home->algae_production_hour(5000);
$home->water_hour(5000);
$home->ore_hour(5000);
$home->needs_recalc(0);
$home->update;

$result = $tester->post('wasterecycling', 'build', [$session_id, $home->id, 3, 3]);

my $building = $db->resultset('Lacuna::DB::Result::Building')->find($result->{result}{building}{id});
$building->finish_upgrade;

$result = $tester->post('wasterecycling', 'recycle', [$session_id, $building->id, 999990000,5,5]);

is($result->{error}{code}, 1011, "can't recycle with waste you don't have");

my $body = $building->body;
$body->algae_stored(20000);
$body->needs_recalc(0);
$body->update;

$result = $tester->post('wasterecycling', 'recycle', [$session_id, $building->id, 5,5,5]);
cmp_ok($result->{result}{seconds_remaining}, '>', 0, "timer is started");

my $water_stored = $building->body->water_stored;

$building = $db->resultset('Lacuna::DB::Result::Building')->find($building->id);
$building->finish_work;
cmp_ok($building->body->water_stored, '>=', $water_stored + 5, "resources increased");



END {
    $tester->cleanup;
}
