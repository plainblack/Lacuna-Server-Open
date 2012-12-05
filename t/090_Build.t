use lib '../lib';
use Test::More tests => 24;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime::Format::Strptime;


use TestHelper;
TestHelper->clear_all_test_empires;
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

$result = $tester->post('malcud', 'repair', [$session_id, $malcud_id]);
ok(exists $result->{result}, 'Can call repair.');


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
my $food = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => -2,
    class           => 'Lacuna::DB::Result::Building::Food::Algae',
    level           => 2,
});
$home->build_building($food);
$food->finish_upgrade;

my $energy = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => -3,
    class           => 'Lacuna::DB::Result::Building::Energy::Hydrocarbon',
    level           => 1,
});
$home->build_building($energy);
$energy->finish_upgrade;

my $water = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => -4,
    class           => 'Lacuna::DB::Result::Building::Water::Purification',
    level           => 4,
});
$home->build_building($water);
$water->finish_upgrade;

my $ore = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => -5,
    class           => 'Lacuna::DB::Result::Building::Ore::Mine',
    level           => 1,
});
$home->build_building($ore);
$ore->finish_upgrade;

# we need a dev ministry so we can upgrade lots of stuff.

my $dev = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => 5,
    class           => 'Lacuna::DB::Result::Building::Development',
    level           => 2,
});
$home->build_building($dev);
$dev->finish_upgrade;

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


$result = $tester->post('university', 'downgrade', [$session_id, $uni->id]);
ok(exists $result->{result}, 'can downgrade the university');

$result = $tester->post('university', 'demolish', [$session_id, $uni->id]);
ok(exists $result->{result}{status}, 'can demolish university');

$home->add_plan('Lacuna::DB::Result::Building::Permanent::EssentiaVein',1);
ok($home->get_plan('Lacuna::DB::Result::Building::Permanent::EssentiaVein',1), 'can add and get a plan');

$result = $tester->post('essentiavein', 'build', [$session_id, $home->id, 5,5]);
ok(exists $result->{result}{status}, 'can build a plan only building');

$db->resultset('Lacuna::DB::Result::Building')->search({class=>'Lacuna::DB::Result::Building::Permanent::EssentiaVein'})->delete; # clean up for future builds

# set up testing of large build queue
$water->level(5);
$water->update;
$food->level(5);
$food->update;
$ore->level(5);
$ore->update;
$energy->level(5);
$energy->update();
$dev->level(5);
$home->needs_recalc(1);
$home->tick;
$home->algae_stored(5000);
$home->energy_stored(5000);
$home->water_stored(5000);
$home->bauxite_stored(105000);
$home->update;

my $format = '%d %m %Y %H:%M:%S %z';

$result = $tester->post('waterpurification', 'build', [$session_id, $home_planet, 3, -5]);
my $date1 = DateTime::Format::Strptime::strptime($format, $result->{result}{building}{pending_build}{end});
my $water1 = $tester->get_building($result->{result}{building}{id});
$result = $tester->post('waterpurification', 'build', [$session_id, $home_planet, 3, -4]);
my $date2 = DateTime::Format::Strptime::strptime($format, $result->{result}{building}{pending_build}{end});
my $water2 = $tester->get_building($result->{result}{building}{id});
$result = $tester->post('waterpurification', 'build', [$session_id, $home_planet, 3, -3]);
my $date3 = DateTime::Format::Strptime::strptime($format, $result->{result}{building}{pending_build}{end});
my $water3 = $tester->get_building($result->{result}{building}{id});

ok($date1 < $date2, 'subsequent builds are adding to queue time 1');
ok($date2 < $date3, 'subsequent builds are adding to queue time 2');

$water1->finish_upgrade;
$water2->finish_upgrade;
$water3->finish_upgrade;

# Make sure non-integer coordinates don't work
$result = $tester->post('waterpurification', 'build', [$session_id, $home_planet, '3.1', -3]);
ok(exists $result->{error}, 'non-integer string attack thwarted!');
$result = $tester->post('waterpurification', 'build', [$session_id, $home_planet, 3.2, -3]);
ok(exists $result->{error}, 'non-integer number attack thwarted!');

$home->add_plan('Lacuna::DB::Result::Building::SpacePort',1,4);
$home->add_plan('Lacuna::DB::Result::Building::SpacePort',1);
$home->add_plan('Lacuna::DB::Result::Building::SpacePort',1,3);
$home->update;

$result = $tester->post('body', 'get_buildable', [$session_id, $home_planet, 4, 4, 'Ships']);
is($result->{result}{buildable}{'Space Port'}{build}{extra_level}, 4, 'Can build the 1+4 plan');
$result = $tester->post('spaceport', 'build', [$session_id, $home->id, 4, 4]);
is($result->{result}{building}{level}, 4, 'New building is level 4 before final upgrade');
my $spaceport = $tester->get_building($result->{result}{building}{id});
$spaceport->finish_upgrade;
$result = $tester->post('spaceport', 'view', [$session_id, $spaceport->id]);
is($result->{result}{building}{level}, 5, 'Finished building is level 5');

END {
    TestHelper->clear_all_test_empires;
}
