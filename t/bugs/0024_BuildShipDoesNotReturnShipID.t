use lib '..','../../lib';
use Test::More tests => 3;
use Test::Deep;
use 5.010;

use strict;
use warnings;

use TestHelper;
TestHelper->clear_all_test_empires;

# BUG building a ship does not return the ship ID in the return status

my $tester = TestHelper->new({ big_producer => 1 })->generate_test_empire->build_infrastructure;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;

my $spaceport = $tester->build_building('Lacuna::DB::Result::Building::SpacePort', 1);
my $shipyard = $tester->build_building('Lacuna::DB::Result::Building::Shipyard',5);

# Build a trade ministry so we can build dorys
my $trade = $tester->build_building('Lacuna::DB::Result::Building::Trade',1);

# now build a new ship
my $result = $tester->post('shipyard', 'build_ship', [$session_id, $shipyard->id, 'dory']);

my $ships_building = $result->{result}{ships_building};

my $first_ship = $ships_building->[0];
my $ship_id = $first_ship->{id};
is($first_ship->{type}, 'dory', 'ship is a Dory');
isnt($ship_id, undef, 'ship ID is defined');

# check that the ship exists
my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($ship_id);
is($ship->type, 'dory', 'ship is in the database');

END {
    TestHelper->clear_all_test_empires;
}
