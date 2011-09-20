use lib '..','../../lib';
use Test::More tests => 2;
use Test::Deep;
use 5.010;

use strict;
use warnings;

use TestHelper;
TestHelper->clear_all_test_empires;

# BUG it is possible to build ships when there are negative docks available

my $tester = TestHelper->new->generate_test_empire->build_infrastructure;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;

$home->ore_hour(50000000);
$home->water_hour(50000000);
$home->energy_hour(50000000);
$home->algae_production_hour(50000000);
$home->ore_capacity(50000000);
$home->energy_capacity(50000000);
$home->food_capacity(50000000);
$home->water_capacity(50000000);
$home->bauxite_stored(50000000);
$home->algae_stored(50000000);
$home->energy_stored(50000000);
$home->water_stored(50000000);
$home->add_happiness(50000000);
$home->needs_recalc(0);
$home->update;


$tester->find_empty_plot;
my $result = $tester->post('spaceport', 'build', [$session_id, $home->id, $tester->x, $tester->y]);
my $spaceport = $tester->get_building($result->{result}{building}{id});
$spaceport->finish_upgrade;

$tester->find_empty_plot;

my $shipyard = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => $tester->x,
    y               => $tester->y,
    class           => 'Lacuna::DB::Result::Building::Shipyard',
    level           => 5,
});
$home->build_building($shipyard);
$shipyard->finish_upgrade;

# Build a trade ministry so we can build dorys
$tester->find_empty_plot;
$result = $tester->post('trade', 'build', [$session_id, $home->id, $tester->x, $tester->y]);
my $trade = $tester->get_building($result->{result}{building}{id});
$trade->finish_upgrade;

# build as many ships as the space port can hold

my @ships;
for ( 0 .. 1 ) {
    my $dory = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'dory'});
    $shipyard->build_ship($dory);
    push @ships, $dory;
}

# now try to post a new one
$result = $tester->post('shipyard', 'build_ship', [$session_id, $shipyard->id, 'dory']);
is($result->{error}{code}, 1009, 'Cannot build ships if there are zero docks available');

# build more than the space port can hold
my $dory = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'dory'});
$shipyard->build_ship($dory);
push @ships, $dory;

# now try to post a new ship
$result = $tester->post('shipyard', 'build_ship', [$session_id, $shipyard->id, 'dory']);
is($result->{error}{code}, 1009, 'Cannot build ships if there are negative docks available');


END {
#    TestHelper->clear_all_test_empires;
}
