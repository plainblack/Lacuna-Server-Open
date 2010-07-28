use lib ('..','../../lib');
use Test::More tests => 24;
use Test::Deep;
use Data::Dumper;
use DateTime;
use 5.010;

use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;

my $empire = $tester->empire;
my $home = $empire->home_planet;
my $db = Lacuna->db;
my $tutorial = Lacuna::Tutorial->new(empire=>$empire);

is($tutorial->finish, 0, 'look at ui - not yet complete');
$home->name(rand(1000000));
is($tutorial->finish, 1, 'look at ui');


my $building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => 1,
    class           => 'Lacuna::DB::Result::Building::Food::Malcud',
});
$home->build_building($building);
$building->finish_upgrade;
is($tutorial->finish, 1, 'get food');


$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => 3,
    class           => 'Lacuna::DB::Result::Building::Water::Purification',
});
$home->build_building($building);
$building->finish_upgrade;
is($tutorial->finish, 1, 'drinking water');


$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => 2,
    class           => 'Lacuna::DB::Result::Building::Energy::Geo',
});
$home->build_building($building);
$building->finish_upgrade;
is($tutorial->finish, 1, 'keep the lights on');


$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => 4,
    class           => 'Lacuna::DB::Result::Building::Ore::Mine',
});
$home->build_building($building);
$building->finish_upgrade;
is($tutorial->finish, 1, 'mine');


$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => 5,
    class           => 'Lacuna::DB::Result::Building::University',
});
$home->build_building($building);
$building->finish_upgrade;
is($tutorial->finish, 1, 'university');


$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => -5,
    class           => 'Lacuna::DB::Result::Building::Ore::Storage',
});
$home->build_building($building);
$building->finish_upgrade;
$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => -4,
    class           => 'Lacuna::DB::Result::Building::Energy::Reserve',
});
$home->build_building($building);
$building->finish_upgrade;
$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => -3,
    class           => 'Lacuna::DB::Result::Building::Food::Reserve',
});
$home->build_building($building);
$building->finish_upgrade;
$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => -2,
    class           => 'Lacuna::DB::Result::Building::Water::Storage',
});
$home->build_building($building);
$building->finish_upgrade;
is($tutorial->finish, 1, 'storage');


$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => -1,
    class           => 'Lacuna::DB::Result::Building::Food::Wheat',
    level           => 2,
});
$home->build_building($building);
$building->finish_upgrade;
$home->tick;
is($tutorial->finish, 1, 'fool');

my $future = DateTime->now->add(hours=>1);
$empire->food_boost($future);
$empire->water_boost($future);
$empire->energy_boost($future);
$empire->ore_boost($future);
$home->tick;
is($tutorial->finish, 1, 'essentia');


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
$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 1,
    y               => -3,
    class           => 'Lacuna::DB::Result::Building::Ore::Mine',
    level           => 2,
});
$home->build_building($building);
$building->finish_upgrade;
$home->tick;
is($tutorial->finish, 1, 'the 300');


$building =Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => -5,
    y               => -5,
    class           => 'Lacuna::DB::Result::Building::Network19',
    level           => 0,
});
$home->build_building($building);
$building->finish_upgrade;
is($tutorial->finish, 1, 'news');


$empire->description('i rule');
is($tutorial->finish, 1, 'rogue');


$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 1,
    y               => -2,
    class           => 'Lacuna::DB::Result::Building::SpacePort',
});
$home->build_building($building);
$building->finish_upgrade;
is($tutorial->finish, 1, 'spaceport');


$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 1,
    y               => -1,
    class           => 'Lacuna::DB::Result::Building::Shipyard',
});
$home->build_building($building);
$building->finish_upgrade;
is($tutorial->finish, 1, 'shipyard');


$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 1,
    y               => 0,
    class           => 'Lacuna::DB::Result::Building::Intelligence',
});
$home->build_building($building);
$building->finish_upgrade;
is($tutorial->finish, 1, 'intelligence');

$building->train_spy;

say "Waiting for spies to finish...";
sleep 216;

my $spies = $building->get_spies;
$spies->next->assign('Counter Espionage');
$spies->next->assign('Counter Espionage');
sleep 3;
is($tutorial->finish, 1, 'counter spy');

$building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 1,
    y               => 1,
    class           => 'Lacuna::DB::Result::Building::Observatory',
});
$home->build_building($building);
$building->finish_upgrade;
is($tutorial->finish, 1, 'observatory');

$empire->add_probe($home->star_id, $home->id);
is($tutorial->finish, 1, 'explore');
is($tutorial->finish, 1, 'the_end');
is($tutorial->finish, 1, 'turing');
is($tutorial->finish, 1, 'turing');
is($tutorial->finish, 1, 'turing');


END {
    $tester->cleanup;
}

