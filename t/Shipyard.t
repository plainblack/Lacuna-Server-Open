use lib '../lib';
use Test::More tests => 2;
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


my $result;


my $uni = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => -1,
    class           => 'Lacuna::DB::Result::Building::University',
    level           => 2,
});
$home->build_building($uni);
$uni->finish_upgrade;

$home->ore_capacity(500000);
$home->energy_capacity(500000);
$home->food_capacity(500000);
$home->water_capacity(500000);
$home->bauxite_stored(500000);
$home->algae_stored(500000);
$home->energy_stored(500000);
$home->water_stored(500000);
$home->energy_hour(500000);
$home->algae_production_hour(500000);
$home->water_hour(500000);
$home->ore_hour(500000);
$home->needs_recalc(0);
$home->update;


$result = $tester->post('spaceport', 'build', [$session_id, $home->id, 0, 1]);
my $spaceport = $empire->get_building('Lacuna::DB::Result::Building::SpacePort',$result->{result}{building}{id});
$spaceport->finish_upgrade;

$home->energy_hour(500000);
$home->algae_production_hour(500000);
$home->water_hour(500000);
$home->ore_hour(500000);
$home->needs_recalc(0);
$home->update;

$result = $tester->post('shipyard', 'build', [$session_id, $home->id, 0, 2]);
ok($result->{result}{building}{id}, "built a shipyard");
my $shipyard = $empire->get_building('Lacuna::DB::Result::Building::Shipyard',$result->{result}{building}{id});
$shipyard->finish_upgrade;


$result = $tester->post('shipyard', 'get_buildable', [$session_id, $shipyard->id]);
is($result->{result}{buildable}{probe}{can}, 0, "ships not buildable yet");

END {
    $tester->cleanup;
}
