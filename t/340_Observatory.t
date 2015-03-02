use lib '../lib';
use Test::More tests => 8;
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

$home->ore_hour(500000);
$home->water_hour(500000);
$home->energy_hour(500000);
$home->algae_production_hour(500000);
$home->ore_capacity(500000);
$home->energy_capacity(500000);
$home->food_capacity(500000);
$home->water_capacity(500000);
$home->bauxite_stored(500000);
$home->algae_stored(500000);
$home->energy_stored(500000);
$home->water_stored(500000);
$home->needs_recalc(0);
$home->update;
$home->tick;

$result = $tester->post('spaceport', 'build', [$session_id, $home->id, 0, 1]);
my $spaceport = $tester->get_building($result->{result}{building}{id});
$spaceport->finish_upgrade;

$result = $tester->post('shipyard', 'build', [$session_id, $home->id, 0, 2]);
my $shipyard = $tester->get_building($result->{result}{building}{id});
$shipyard->level(2);
$shipyard->finish_upgrade;

$result = $tester->post('observatory', 'build', [$session_id, $home->id, 0, 3]);
ok($result->{result}{building}{id}, "built an observatory");
my $observatory = $tester->get_building($result->{result}{building}{id});
$observatory->finish_upgrade;

$result = $tester->post('shipyard', 'get_buildable', [$session_id, $shipyard->id]);
is($result->{result}{buildable}{probe}{can}, 1, "probes are buildable");

$result = $tester->post('shipyard', 'build_ship', [$session_id, $shipyard->id, 'probe']);
$result = $tester->post('shipyard', 'build_ship', [$session_id, $shipyard->id, 'probe']);
ok(exists $result->{result}{ships_building}[0]{date_completed}, "got a date of completion");
is($result->{result}{ships_building}[0]{type}, 'probe', "probe building");

$tester->finish_ships( $shipyard->id );

$result = $tester->post('spaceport', 'view', [$session_id, $spaceport->id]);
is($result->{result}{docked_ships}{probe}, 2, "we have 2 probes built");

my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({body_id => $home->id, type=>'probe'})->first;
$result = $tester->post('spaceport', 'send_ship', [$session_id, $ship->id, {star_id=>6}]);
ok($result->{result}{ship}{date_arrives}, "probe sent");

$ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$ship->id})->first;
$ship->arrive;

$empire = $tester->empire(Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($empire->id));
is($empire->count_probed_stars, 2, "2 stars probed!");

$result = $tester->post('spaceport', 'view', [$session_id, $spaceport->id]);
is($result->{result}{docked_ships}{probe}, 1, "we have one probe left");


END {
    TestHelper->clear_all_test_empires;
}
