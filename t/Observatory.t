use lib '../lib';
use Test::More tests => 8;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;

use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;

my $result;

my $uni = Lacuna::DB::Building::University->new(
    simpledb        => $tester->db,
    x               => 0,
    y               => -1,
    class           => 'Lacuna::DB::Building::University',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 5,
);
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
$home->put;

$result = $tester->post('spaceport', 'build', [$session_id, $home->id, 0, 1]);
my $spaceport = $empire->get_building('Lacuna::DB::Building::SpacePort',$result->{result}{building}{id});
$spaceport->finish_upgrade;

$home->energy_hour(500000);
$home->algae_production_hour(500000);
$home->water_hour(500000);
$home->ore_hour(500000);
$home->needs_recalc(0);
$home->put;

$result = $tester->post('shipyard', 'build', [$session_id, $home->id, 0, 2]);
my $shipyard = $empire->get_building('Lacuna::DB::Building::Shipyard',$result->{result}{building}{id});
$shipyard->finish_upgrade;

$home->energy_hour(500000);
$home->algae_production_hour(500000);
$home->water_hour(500000);
$home->ore_hour(500000);
$home->needs_recalc(0);
$home->put;


$result = $tester->post('observatory', 'build', [$session_id, $home->id, 0, 3]);
ok($result->{result}{building}{id}, "built an observatory");
my $observatory = $empire->get_building('Lacuna::DB::Building::Observatory',$result->{result}{building}{id});
$observatory->finish_upgrade;

$result = $tester->post('shipyard', 'get_buildable', [$session_id, $shipyard->id]);
is($result->{result}{buildable}{probe}{can}, 1, "probes are buildable");

$home->ore_capacity(500000);
$home->energy_capacity(500000);
$home->food_capacity(500000);
$home->water_capacity(500000);
$home->bauxite_stored(500000);
$home->algae_stored(500000);
$home->energy_stored(500000);
$home->water_stored(500000);
$home->needs_recalc(0);
$home->put;

$result = $tester->post('shipyard', 'build_ship', [$session_id, $shipyard->id, 'probe', 3]);
ok(exists $result->{result}{ships_building}[0]{date_completed}, "got a date of completion");
is($result->{result}{ships_building}[0]{type}, 'probe', "probe building");

my $finish = DateTime->now;
$tester->db->domain('ship_builds')->search(where=>{shipyard_id=>$shipyard->id})->update({date_completed=>$finish});
sleep 3;

$result = $tester->post('spaceport', 'view', [$session_id, $spaceport->id]);
is($result->{result}{docked_ships}{probe}, 2, "we have 2 probes built");

$result = $tester->post('spaceport', 'send_probe', [$session_id, $home->id, {star_name=>'Rozeske'}]);
ok($result->{result}{probe}{date_arrives}, "probe sent");

my $ship = $tester->db->domain('travel_queue')->search(where => {body_id => $home->id}, consistent=>1)->next;
$ship->arrive;
$empire = $tester->empire($tester->db->domain('empire')->find($empire->id));
is($empire->count_probed_stars, 2, "2 stars probed!");

$result = $tester->post('spaceport', 'view', [$session_id, $spaceport->id]);
is($result->{result}{docked_ships}{probe}, 1, "we have one probe left");

END {
    $tester->cleanup;
}
