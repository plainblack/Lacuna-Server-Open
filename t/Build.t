use lib '../lib';
use Test::More tests => 19;
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

$result = $tester->post('body', 'get_status', [$session_id, $home_planet]);
my $last_energy = $result->{result}{body}{energy_stored};

$result = $tester->post('malcud', 'build', [$session_id, $home_planet, 3, 3]);
ok($result->{result}{building}{id}, 'Can build buildings');
is($result->{result}{building}{level}, 0, 'New building is level 0');
cmp_ok($result->{result}{building}{pending_build}{seconds_remaining}, '>', 0, 'Building has time in queue');
my $malcud_id = $result->{result}{building}{id};
$result = $tester->post('body', 'get_status', [$session_id, $home_planet]);
cmp_ok($last_energy, '>', $result->{result}{body}{energy_stored}, 'Resources are being spent.');

$result = $tester->post('body', 'get_build_queue', [$session_id, $home_planet]);
cmp_ok($result->{result}{build_queue}{$malcud_id}, '>', 0, "get_build_queue");

my $building = $db->resultset('Lacuna::DB::Result::Building')->find($malcud_id);
$building->finish_upgrade;

$result = $tester->post('malcud', 'view', [$session_id, $building->id]);
is($result->{result}{building}{level}, 1, 'New building is built');
ok(ref $result->{result}{building}{pending_build} ne 'HASH', 'Building is no longer in build queue');
$result = $tester->post('body', 'get_status', [$session_id, $home_planet]);
$last_energy = $result->{result}{body}{energy_stored};



my $empire = $db->resultset('Lacuna::DB::Result::Empire')->find($empire_id);
my $home = $empire->home_planet;

# quick build basic university
my $uni = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => -1,
    class           => 'Lacuna::DB::Result::Building::University',
    level           => 2,
});
$home->build_building($uni);
$uni->finish_upgrade;


# build some infrastructure
my $infrastructure = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => -5,
    y               => -5,
    class           => 'Lacuna::DB::Result::Building::Food::Algae',
    level           => 1,
});
$home->build_building($infrastructure);
$infrastructure->finish_upgrade;

$infrastructure = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => -5,
    y               => -5,
    class           => 'Lacuna::DB::Result::Building::Energy::Hydrocarbon',
    level           => 1,
});
$home->build_building($infrastructure);
$infrastructure->finish_upgrade;

my $water = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => -5,
    y               => -5,
    class           => 'Lacuna::DB::Result::Building::Water::Purification',
    level           => 3,
});
$home->build_building($water);
$water->finish_upgrade;

$infrastructure = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => -5,
    y               => -5,
    class           => 'Lacuna::DB::Result::Building::Ore::Mine',
    level           => 1,
});
$home->build_building($infrastructure);
$infrastructure->finish_upgrade;


# provide the resources to upgrade the university
$home->bauxite_stored(5000);
$home->algae_stored(5000);
$home->energy_stored(5000);
$home->water_stored(5000);
$home->update;

# see if the university is upgradable to level 2
$result = $tester->post('university','view', [$session_id, $uni->id]);
ok($result->{result}{building}{upgrade}{can}, 'university can be upgraded');

# get it over with already
$uni->start_upgrade;
$uni->finish_upgrade;

$home->bauxite_stored(5000);
$home->algae_stored(5000);
$home->energy_stored(5000);
$home->water_stored(5000);
$home->update;

$last_energy = 5000;

# now let's make sure that other buildings can be upgraded too
$result = $tester->post('malcud', 'upgrade', [$session_id, $building->id]);
is($result->{result}{building}{level}, 1, 'Upgrading building is still level 1');
cmp_ok($result->{result}{building}{pending_build}{seconds_remaining}, '>', 0, 'Upgrade has time in queue');
cmp_ok($last_energy, '>', $result->{result}{status}{body}{energy_stored}, 'Resources are being spent for upgrade.');


# simulate upgrade attack
$result = $tester->post('malcud', 'upgrade', [$session_id, $building->id]);
ok(exists $result->{error}, 'attack thwarted!');
$result = $tester->post('malcud', 'upgrade', [$session_id, $building->id]);
ok(exists $result->{error}, 'attack thwarted!!');
$result = $tester->post('malcud', 'upgrade', [$session_id, $building->id]);
ok(exists $result->{error}, 'attack thwarted!!!');

$result = $tester->post('malcud', 'get_stats_for_level', [$session_id, $building->id, 15]);
ok(exists $result->{result}, 'get_stats_for_level works');

$result = $tester->post('body', 'get_status', [$session_id, $home->id]);


$result = $tester->post('waterpurification', 'demolish', [$session_id, $water->id]);
ok(exists $result->{error}, 'can not demolish water purification plant');

$result = $tester->post('university', 'demolish', [$session_id, $uni->id]);
ok(exists $result->{result}{status}, 'can demolish university');

$result = $tester->post('malcud', 'demolish', [$session_id, $malcud_id]);

$home->add_plan('Lacuna::DB::Result::Building::Permanent::EssentiaVein',1);
ok($home->get_plan('Lacuna::DB::Result::Building::Permanent::EssentiaVein',1), 'can add and get a plan');

$result = $tester->post('essentiavein', 'build', [$session_id, $home->id, 5,5]);
ok(exists $result->{result}{status}, 'can build a plan only building');


END {
    $tester->cleanup;
}
