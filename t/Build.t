use lib '../lib';
use Test::More tests => 11;
use Test::Deep;
use Data::Dumper;
use 5.010;


use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;

my $result;

my $last_energy = $tester->empire->home_planet->energy_stored;
my $empire_id = $tester->empire->id;
my $home_planet = $tester->empire->home_planet_id;
my $db = $tester->db;

$result = $tester->post('wheat', 'build', [$session_id, $home_planet, 3, 3]);
is($result->{result}{building}{name}, 'Wheat Farm', 'Can build buildings');
is($result->{result}{building}{level}, 0, 'New building is level 0');
cmp_ok($result->{result}{building}{pending_build}{seconds_remaining}, '>', 0, 'Building has time in queue');
cmp_ok($last_energy, '>', $result->{result}{status}{empire}{planets}{$home_planet}{energy_stored}, 'Resources are being spent.');
my $wheat_id = $result->{result}{building}{id};

$result = $tester->post('body', 'get_build_queue', [$session_id, $home_planet]);
cmp_ok($result->{result}{build_queue}{$wheat_id}, '>', 0, "get_build_queue");

my $building = $db->domain('food')->find($wheat_id);
$building->finish_upgrade;

$result = $tester->post('wheat', 'view', [$session_id, $building->id]);
is($result->{result}{building}{level}, 1, 'New building is built');
ok(! exists $result->{result}{building}{pending_build}, 'Building is no longer in build queue');
$last_energy = $result->{result}{status}{empire}{planets}{$home_planet}{energy_stored};



my $empire = $db->domain('empire')->find($empire_id);
my $home = $empire->home_planet;

# quick build basic university
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
    level           => 2,
);
$home->build_building($uni);
$uni->finish_upgrade;

# provide the resources to upgrade the university
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
$home->put;

# see if the university is upgradable to level 2
$result = $tester->post('university','view', [$session_id, $uni->id]);
ok($result->{result}{building}{upgrade}{can}, 'university can be upgraded');

# get it over with already
$uni->start_upgrade;
$uni->finish_upgrade;
#$empire->university_level(5);
#$empire->put;

# now let's make sure that other buildings can be upgraded too
$result = $tester->post('wheat', 'upgrade', [$session_id, $building->id]);
is($result->{result}{building}{level}, 1, 'Upgrading building is still level 1');
cmp_ok($result->{result}{building}{pending_build}{seconds_remaining}, '>', 0, 'Upgrade has time in queue');
cmp_ok($last_energy, '>', $result->{result}{status}{empire}{planets}{$home_planet}{energy_stored}, 'Resources are being spent for upgrade.');


END {
    $tester->cleanup;
}
