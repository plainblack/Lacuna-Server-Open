use lib '../lib';
use Test::More tests => 15;
use Test::Deep;
use Data::Dumper;
use 5.010;


use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;

my $result;

my $empire_id = $tester->empire->id;
my $home_planet = $tester->empire->home_planet_id;
my $db = Lacuna->db;

$result = $tester->post('empire', 'get_full_status', [$session_id]);
my $last_energy = $result->{result}{empire}{planets}{$home_planet}{energy_stored};

$result = $tester->post('wheat', 'build', [$session_id, $home_planet, 3, 3]);
ok($result->{result}{building}{id}, 'Can build buildings');
is($result->{result}{building}{level}, 0, 'New building is level 0');
cmp_ok($result->{result}{building}{pending_build}{seconds_remaining}, '>', 0, 'Building has time in queue');
my $wheat_id = $result->{result}{building}{id};
$result = $tester->post('empire', 'get_full_status', [$session_id]);
cmp_ok($last_energy, '>', $result->{result}{empire}{planets}{$home_planet}{energy_stored}, 'Resources are being spent.');

$result = $tester->post('body', 'get_build_queue', [$session_id, $home_planet]);
cmp_ok($result->{result}{build_queue}{$wheat_id}, '>', 0, "get_build_queue");

my $building = $db->resultset('Lacuna::DB::Result::Building')->find($wheat_id);
$building->finish_upgrade;

$result = $tester->post('wheat', 'view', [$session_id, $building->id]);
is($result->{result}{building}{level}, 1, 'New building is built');
ok(! exists $result->{result}{building}{pending_build}, 'Building is no longer in build queue');
$result = $tester->post('empire', 'get_full_status', [$session_id]);
$last_energy = $result->{result}{empire}{planets}{$home_planet}{energy_stored};



my $empire = $db->resultset('Lacuna::DB::Result::Empire')->find($empire_id);
my $home = $empire->home_planet;

# quick build basic university
my $uni = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new(
    x               => 0,
    y               => -1,
    class           => 'Lacuna::DB::Result::Building::University',
    level           => 2,
);
$home->build_building($uni);
$uni->finish_upgrade;

# provide the resources to upgrade the university
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

# see if the university is upgradable to level 2
$result = $tester->post('university','view', [$session_id, $uni->id]);
ok($result->{result}{building}{upgrade}{can}, 'university can be upgraded');

# get it over with already
$uni->start_upgrade;
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

$result = $tester->post('empire', 'get_full_status', [$session_id]);
$last_energy = $result->{result}{empire}{planets}{$home_planet}{energy_stored};

# now let's make sure that other buildings can be upgraded too
$result = $tester->post('wheat', 'upgrade', [$session_id, $building->id]);
is($result->{result}{building}{level}, 1, 'Upgrading building is still level 1');
cmp_ok($result->{result}{building}{pending_build}{seconds_remaining}, '>', 0, 'Upgrade has time in queue');
$result = $tester->post('empire', 'get_full_status', [$session_id]);
cmp_ok($last_energy, '>', $result->{result}{empire}{planets}{$home_planet}{energy_stored}, 'Resources are being spent for upgrade.');


# simulate upgrade attack
$result = $tester->post('wheat', 'upgrade', [$session_id, $building->id]);
ok(exists $result->{error}, 'attack thwarted!');
$result = $tester->post('wheat', 'upgrade', [$session_id, $building->id]);
ok(exists $result->{error}, 'attack thwarted!!');
$result = $tester->post('wheat', 'upgrade', [$session_id, $building->id]);
ok(exists $result->{error}, 'attack thwarted!!!');

$result = $tester->post('wheat', 'get_stats_for_level', [$session_id, $building->id, 15]);
ok(exists $result->{result}, 'get_stats_for_level works');

END {
    $tester->cleanup;
}
