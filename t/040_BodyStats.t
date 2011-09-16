use lib '../lib';
use Test::More tests => 20;
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

my $initial_status = $home->get_status($empire);

my $wheat = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => 1,
    class           => 'Lacuna::DB::Result::Building::Food::Wheat',
});
$home->build_building($wheat);
$wheat->finish_upgrade;

my $after_wheat = $home->get_status($empire);

cmp_ok($initial_status->{food_hour}, '<', $after_wheat->{food_hour}, "food_hour raised");
cmp_ok($initial_status->{ore_hour}, '>', $after_wheat->{ore_hour}, "ore_hour lowered");
cmp_ok($initial_status->{energy_hour}, '>', $after_wheat->{energy_hour}, "energy_hour lowered");
cmp_ok($initial_status->{water_hour}, '>', $after_wheat->{water_hour}, "water_hour lowered");
cmp_ok($initial_status->{waste_hour}, '<', $after_wheat->{waste_hour}, "waste_hour raised");

my $water = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => 2,
    class           => 'Lacuna::DB::Result::Building::Water::Purification',
});
$home->build_building($water);
$water->finish_upgrade;

my $after_water = $home->get_status($empire);

cmp_ok($after_wheat->{food_hour}, '>', $after_water->{food_hour}, "food_hour lowered");
cmp_ok($after_wheat->{ore_hour}, '>', $after_water->{ore_hour}, "ore_hour lowered");
cmp_ok($after_wheat->{energy_hour}, '>', $after_water->{energy_hour}, "energy_hour lowered");
cmp_ok($after_wheat->{water_hour}, '<', $after_water->{water_hour}, "water_hour raised");
cmp_ok($after_wheat->{waste_hour}, '<', $after_water->{waste_hour}, "waste_hour raised");

my $we = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => 3,
    class           => 'Lacuna::DB::Result::Building::Energy::Waste',
});
$home->build_building($we);
$we->finish_upgrade;

my $after_we = $home->get_status($empire);

cmp_ok($after_water->{food_hour}, '>', $after_we->{food_hour}, "food_hour lowered");
cmp_ok($after_water->{ore_hour}, '>', $after_we->{ore_hour}, "ore_hour lowered");
cmp_ok($after_water->{energy_hour}, '<', $after_we->{energy_hour}, "energy_hour raised");
cmp_ok($after_water->{water_hour}, '>', $after_we->{water_hour}, "water_hour lowered");
cmp_ok($after_water->{waste_hour}, '>', $after_we->{waste_hour}, "waste_hour lowered");


my $ws = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => 4,
    class           => 'Lacuna::DB::Result::Building::Waste::Sequestration',
});
$home->build_building($ws);

$ws->finish_upgrade;

my $after_ws = $home->get_status($empire);
cmp_ok($after_we->{waste_capacity}, '<', $after_ws->{waste_capacity}, "waste_capacity raised");


my $os = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => 5,
    class           => 'Lacuna::DB::Result::Building::Ore::Storage',
});
$home->build_building($os);

$os->finish_upgrade;

my $after_os = $home->get_status($empire);
cmp_ok($after_ws->{ore_capacity}, '<', $after_os->{ore_capacity}, "ore_capacity raised");

is($empire->university_level, 0, 'university is 0');
my $uni = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => -1,
    class           => 'Lacuna::DB::Result::Building::University',
});
$home->build_building($uni);

$uni->finish_upgrade;
is($empire, $home->empire, 'do we still share the empire object');
is($empire->university_level, 1, 'university is 1');



END {
    TestHelper->clear_all_test_empires;
}

