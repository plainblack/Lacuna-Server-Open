use lib '../lib';
use Test::More tests => 2;
use Test::Deep;
use Data::Dumper;
use 5.010;

use TestHelper;
TestHelper->clear_all_test_empires;

my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;
my $result;
$empire->add_essentia({ amount => 10, reason => 'testing development'});
$empire->update;

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
$home->ore_hour(5000);
$home->energy_hour(5000);
$home->algae_production_hour(5000);
$home->water_hour(5000);
$home->needs_recalc(0);
$home->update;

$result = $tester->post('development', 'build', [$session_id, $tester->empire->home_planet_id, 3, 3]);
my $id =  $result->{result}{building}{id};
$result = $tester->post('development', 'view', [$session_id, $id]);

is($result->{result}{build_queue}[0]{name}, 'Development Ministry', "got build queue");

$result = $tester->post('development', 'subsidize_build_queue', [$session_id, $id]);
ok($result->{result}{essentia_spent}, 'subsidy worked');

END {
    TestHelper->clear_all_test_empires;
}
