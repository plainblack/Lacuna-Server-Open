use lib ('..','../../lib');
use strict;
use Test::More tests => 5;
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


$home->bauxite_hour(1000);
$home->ore_hour(1000);
$home->ore_capacity(5000);
$home->energy_hour(1000);
$home->energy_capacity(5000);
$home->water_hour(1000);
$home->water_capacity(5000);
$home->waste_hour(1000);
$home->waste_capacity(5000);
$home->algae_production_hour(1000);
$home->food_capacity(5000);
$home->needs_recalc(0);
$home->update;

my $original_ore = $home->ore_stored;
my $original_energy = $home->energy_stored;
my $original_water = $home->water_stored;
my $original_waste = $home->waste_stored;
my $original_food = $home->food_stored;

say "Please wait 60 seconds.";
sleep 60; # wait 60 seconds to tick again.

$home->tick;

my $ore_now = $home->ore_stored;
my $energy_now = $home->energy_stored;
my $water_now = $home->water_stored;
my $waste_now = $home->waste_stored;
my $food_now = $home->food_stored;

cmp_ok($ore_now - $original_ore, '>=', 16, 'ore');
cmp_ok($energy_now - $original_energy, '>=', 16, 'energy');
cmp_ok($water_now - $original_water, '>=', 16, 'water');
cmp_ok($waste_now - $original_waste, '>=', 16, 'waste');
cmp_ok($food_now - $original_food, '>=', 16, 'food');


END {
    $tester->cleanup;
}

