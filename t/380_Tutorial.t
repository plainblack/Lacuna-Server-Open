use lib ('..','../lib');
use Test::More tests => 25;
use Test::Deep;
use Data::Dumper;
use DateTime;
use 5.010;

use TestHelper;
TestHelper->clear_all_test_empires;

my $tester = TestHelper->new->generate_test_empire;

my $session_id = $tester->session->id;

my $empire = $tester->empire;
my $home = $empire->home_planet;
my $db = Lacuna->db;
my $tutorial = Lacuna::Tutorial->new(empire=>$empire);

is($tutorial->finish, 0, 'look at ui - not yet complete');
$home->name(rand(1000000));
is($tutorial->finish, 1, 'look at ui');

is($empire->tutorial_stage, 'get_food', 'get_food');
my $building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => -5,
    y               => -5,
    class           => 'Lacuna::DB::Result::Building::Food::Malcud',
});
$home->build_building($building);
$building->finish_upgrade;
$home->tick;
is($empire->tutorial_stage, 'drinking_water', 'drinking water');

$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => -4,
    y               => -5,
    class           => 'Lacuna::DB::Result::Building::Water::Purification',
});
$home->build_building($building);
$building->finish_upgrade;
$home->tick;
is($empire->tutorial_stage, 'keep_the_lights_on', 'keep the lights on');

$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => -3,
    y               => -5,
    class           => 'Lacuna::DB::Result::Building::Energy::Geo',
});
$home->build_building($building);
$building->finish_upgrade;
$home->tick;
is($empire->tutorial_stage, 'mine', 'mine');


$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => -2,
    y               => -5,
    class           => 'Lacuna::DB::Result::Building::Ore::Mine',
});
$home->build_building($building);
$building->finish_upgrade;
$home->tick;
is($empire->tutorial_stage, 'more_resources', 'more resources');


$building = $home->command;
$building->start_upgrade;
$building->level( $building->level + 1 ); # extra upgrade level
$building->finish_upgrade;
$home->tick;
is($empire->tutorial_stage,'university', 'university');


$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => -1,
    y               => -5,
    class           => 'Lacuna::DB::Result::Building::University',
});
$home->build_building($building);
$building->finish_upgrade;
$home->tick;
is($empire->tutorial_stage, 'mission_command', 'mission_command');
$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => -1, 
    y               => -5, 
    class           => 'Lacuna::DB::Result::Building::MissionCommand',
});
$home->build_building($building);
$building->finish_upgrade;
$home->tick;



is($empire->tutorial_stage, 'storage', 'university');


$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => -5,
    class           => 'Lacuna::DB::Result::Building::Ore::Storage',
});
$home->build_building($building);
$building->finish_upgrade;
$home->tick;
$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => -4,
    class           => 'Lacuna::DB::Result::Building::Energy::Reserve',
});
$home->build_building($building);
$building->finish_upgrade;
$home->tick;
$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => -3,
    class           => 'Lacuna::DB::Result::Building::Food::Reserve',
});
$home->build_building($building);
$building->finish_upgrade;
$home->tick;
$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => -2,
    class           => 'Lacuna::DB::Result::Building::Water::Storage',
});
$home->build_building($building);
$building->finish_upgrade;
$home->tick;
is($empire->tutorial_stage, 'fool', 'storage');


$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => -1,
    class           => 'Lacuna::DB::Result::Building::Food::Wheat',
    level           => 2,
});
$home->build_building($building);
$building->finish_upgrade;
$home->tick;

my $future = DateTime->now->add(hours=>1);
$empire->food_boost($future);
$empire->water_boost($future);
$empire->energy_boost($future);
$empire->ore_boost($future);
$home->tick;

$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 1,
    y               => -5,
    class           => 'Lacuna::DB::Result::Building::Energy::Geo',
    level           => 3,
});
$home->build_building($building);
$building->finish_upgrade;
$home->tick;
is($tutorial->finish, 1, 'energy');


$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 1,
    y               => -4,
    class           => 'Lacuna::DB::Result::Building::Water::Purification',
    level           => 2,
});
$home->build_building($building);
$building->finish_upgrade;
$home->tick;
$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 1,
    y               => -3,
    class           => 'Lacuna::DB::Result::Building::Ore::Mine',
    level           => 2,
});
$home->build_building($building);
$building->finish_upgrade;
$home->tick;
is($empire->tutorial_stage, 'news', 'the 300');


$building =Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => -5,
    y               => -5,
    class           => 'Lacuna::DB::Result::Building::Network19',
    level           => 0,
});
$home->build_building($building);
$building->finish_upgrade;
$home->tick;
is($empire->tutorial_stage, 'rogue', 'news');


$empire->description('i rule');
is($tutorial->finish, 1, 'rogue');


$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 1,
    y               => -2,
    class           => 'Lacuna::DB::Result::Building::SpacePort',
});
$home->build_building($building);
$building->finish_upgrade;
$home->tick;
is($empire->tutorial_stage, 'shipyard', 'spaceport');


$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 1,
    y               => -1,
    class           => 'Lacuna::DB::Result::Building::Shipyard',
});
$home->build_building($building);
$building->finish_upgrade;
$home->tick;
is($empire->tutorial_stage, 'pawn', 'shipyard');


$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 1,
    y               => 0,
    class           => 'Lacuna::DB::Result::Building::Intelligence',
});
$home->build_building($building);
$building->level( $building->level + 1 ); # extra upgrade level
$building->finish_upgrade;
$home->tick;
is($empire->tutorial_stage, 'counter_spy', 'intelligence');

$building->train_spy;

my $spies = $building->get_spies;
foreach (1..2) {
    my $spy = $spies->next;
    $spy->empire($empire);
    $spy->available_on(DateTime->now);
    $spy->task('Idle');
    $spy->assign('Counter Espionage');
}
$home->tick;

is($empire->tutorial_stage, 'observatory', 'counter spy');

$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 1,
    y               => 1,
    class           => 'Lacuna::DB::Result::Building::Observatory',
});
$home->build_building($building);
$building->finish_upgrade;
$home->tick;
is($empire->tutorial_stage, 'explore', 'observatory');

$empire->add_observatory_probe($home->star_id, $home->id);
$home->tick;

is($empire->tutorial_stage, 'the_end', 'explore');
is($tutorial->finish, 1, 'the_end');
is($tutorial->finish, 1, 'turing');
is($tutorial->finish, 1, 'turing');
is($tutorial->finish, 1, 'turing');


END {
    TestHelper->clear_all_test_empires;
}

