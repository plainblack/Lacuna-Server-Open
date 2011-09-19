use lib '../lib';
use Test::More tests => 4;
use Test::Deep;
use Data::Dumper;
use 5.010;

use TestHelper;
TestHelper->clear_all_test_empires;

my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;
my $db = Lacuna->db;

my $result;

my $uni = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => -1,
    class           => 'Lacuna::DB::Result::Building::University',
    level           => 5,
});
$home->build_building($uni);
$uni->finish_upgrade;

$home->ore_capacity(500000);
$home->energy_capacity(500000);
$home->food_capacity(500000);
$home->water_capacity(500000);
$home->bauxite_stored(500000);
$home->energy_stored(500000);
$home->water_stored(500000);
$home->energy_hour(500000);
$home->algae_production_hour(500000);
$home->water_hour(500000);
$home->ore_hour(500000);
$home->needs_recalc(0);
$home->update;

$result = $tester->post('park', 'build', [$session_id, $empire->home_planet_id, 3, 3]);

my $building = $db->resultset('Lacuna::DB::Result::Building')->find($result->{result}{building}{id});
$building->finish_upgrade;

$result = $tester->post('park', 'throw_a_party', [$session_id, $building->id]);

is($result->{error}{code}, 1011, "can't throw a party without food");

my $body = $building->body;
$body->algae_stored(20000);
$body->update;

$result = $tester->post('park', 'throw_a_party', [$session_id, $building->id]);
cmp_ok($result->{result}{party}{seconds_remaining}, '>', 0, "timer is started");
$result = $tester->post('park', 'view', [$session_id, $building->id]);
cmp_ok($result->{result}{status}{planets}[0]{food_stored}, '<', 20_000, "food gets spent");
my $happy = $result->{result}{status}{planets}[0]{happiness};

$building = $db->resultset('Lacuna::DB::Result::Building')->find($result->{result}{building}{id});
$building->finish_work;
cmp_ok($result->{result}{status}{planets}[0]{happiness}, '<', $building->body->happiness, "happiness is increased");

END {
    TestHelper->clear_all_test_empires;
}
