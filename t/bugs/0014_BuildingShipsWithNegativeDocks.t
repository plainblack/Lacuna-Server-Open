use lib '..','../../lib';
use Test::More tests => 2;
use Test::Deep;
use 5.010;

use strict;
use warnings;

use TestHelper;
TestHelper->clear_all_test_empires;

# BUG it is possible to build ships when there are negative docks available

my $tester = TestHelper->new({ big_producer => 1 })->generate_test_empire->build_infrastructure;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;

my $spaceport = $tester->build_building('Lacuna::DB::Result::Building::SpacePort', 1);
my $shipyard = $tester->build_building('Lacuna::DB::Result::Building::Shipyard',5);

# Build a trade ministry so we can build dorys
my $trade = $tester->build_building('Lacuna::DB::Result::Building::Trade',1);

# build as many ships as the space port can hold

my @ships;
for ( 0 .. 1 ) {
    my $dory = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'dory'});
    $shipyard->build_ship($dory);
    push @ships, $dory;
}

# now try to build a new ship
my $result = $tester->post('shipyard', 'build_ship', [$session_id, $shipyard->id, 'dory']);
is($result->{error}{code}, 1009, 'Cannot build ships if there are zero docks available');

# build more than the space port can hold
my $dory = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'dory'});
$shipyard->build_ship($dory);
push @ships, $dory;

# now try to build a new ship
$result = $tester->post('shipyard', 'build_ship', [$session_id, $shipyard->id, 'dory']);
is($result->{error}{code}, 1009, 'Cannot build ships if there are negative docks available');


END {
    TestHelper->clear_all_test_empires;
}
