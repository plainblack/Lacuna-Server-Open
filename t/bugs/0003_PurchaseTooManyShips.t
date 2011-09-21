use lib '..','../../lib';
use Test::More tests => 2;
use Test::Deep;
use 5.010;

use strict;
use warnings;

use TestHelper;
TestHelper->clear_all_test_empires;

# BUG it is possible to purchase more ships than your space port can hold. 

my $tester = TestHelper->new({ big_producer => 1 })->generate_test_empire->build_infrastructure;
my $tester_session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;
$empire->add_essentia(100, 'testing transporter')->update;

my $trader = TestHelper->new({empire_name => 'TLE Test Trader', big_producer => 1})->generate_test_empire->build_infrastructure;
my $trader_session_id = $trader->session->id;
$trader->empire->add_essentia(100, 'testing transporter')->update;

# Build an SST and a space port on both the tester and the trader empires

my $tester_spaceport   = $tester->build_building('Lacuna::DB::Result::Building::SpacePort',   2);
my $tester_shipyard    = $tester->build_building('Lacuna::DB::Result::Building::Shipyard',    2);
my $tester_transporter = $tester->build_building('Lacuna::DB::Result::Building::Transporter', 10);
my $trader_spaceport   = $trader->build_building('Lacuna::DB::Result::Building::SpacePort',   2);
my $trader_shipyard    = $trader->build_building('Lacuna::DB::Result::Building::Shipyard',    2);
my $trader_transporter = $trader->build_building('Lacuna::DB::Result::Building::Transporter', 10);

# build just under the max ships the tester space port can hold
for ( 0 .. 2 ) {
    my $dory = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'dory'});
    $tester_shipyard->build_ship($dory);
}
$tester->finish_ships($tester_shipyard->id);

# build some ships for the trader to trade

my @ships;
for ( 0 .. 3 ) {
    my $dory = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'dory'});
    $trader_shipyard->build_ship($dory);
    push @ships, $dory;
}
$trader->finish_ships($trader_shipyard->id);

# Trader puts 4 ships on the SST
my $result = $trader->post('transporter', 'add_to_market', [$trader_session_id, $trader_transporter->id, [
    { type => 'ship', ship_id => $ships[0]->id},
    { type => 'ship', ship_id => $ships[1]->id},
    { type => 'ship', ship_id => $ships[2]->id},
    { type => 'ship', ship_id => $ships[3]->id},
], 1]);
my $trade_id = $result->{result}{trade_id};
ok($trade_id, 'there is a trade');

Lacuna->cache->set('captcha', $tester_session_id, { guid => 1111, solution => 1111 }, 60 * 15 );
$tester->post('captcha', 'solve', [$tester_session_id, 1111, 1111]);

$result = $tester->post('transporter', 'accept_from_market', [$tester_session_id, $tester_transporter->id, $trade_id]);
is($result->{error}{code}, 1009, 'Cannot accept more ships than the space port can accept');






END {
#    TestHelper->clear_all_test_empires;
}
