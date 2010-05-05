use lib '../lib';
use Test::More tests => 1;
use Test::Deep;
use Data::Dumper;
use 5.010;

use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;

my $result;

my $uni = Lacuna::DB::Result::Building::University->new(
    simpledb        => $tester->db,
    x               => 0,
    y               => -1,
    class           => 'Lacuna::DB::Result::Building::University',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 1,
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

$result = $tester->post('foodreserve', 'build', [$session_id, $tester->empire->home_planet_id, 3, 3]);
my $building_id = $result->{result}{building}{id};
$result = $tester->post('foodreserve', 'view', [$session_id, $building_id]);

cmp_ok($result->{result}{food_stored}{algae}, '>', 0, "got food storage");


END {
    $tester->cleanup;
}
