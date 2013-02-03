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
$empire->add_essentia({ amount => 100, reason => 'testing transporter'});
$empire->update;

my $trader = TestHelper->new({empire_name => 'TLE Test Trader', big_producer => 1})->generate_test_empire->build_infrastructure;
my $trader_session_id = $trader->session->id;
$trader->empire->add_essentia({ amount => 100, reason => 'testing transporter'});
$trader->empire->update;

# Build an SST and a space port on both the tester and the trader empires

my $tester_spaceport   = $tester->build_building('Lacuna::DB::Result::Building::SpacePort',   2);
my $tester_shipyard    = $tester->build_building('Lacuna::DB::Result::Building::Shipyard',    2);
my $tester_transporter = $tester->build_building('Lacuna::DB::Result::Building::Transporter', 10);
my $tester_trade       = $tester->build_building('Lacuna::DB::Result::Building::Trade',       10);

my $trader_spaceport   = $trader->build_building('Lacuna::DB::Result::Building::SpacePort',   8);
my $trader_shipyard    = $trader->build_building('Lacuna::DB::Result::Building::Shipyard',    8);
my $trader_transporter = $trader->build_building('Lacuna::DB::Result::Building::Transporter', 10);
my $trader_trade       = $trader->build_building('Lacuna::DB::Result::Building::Trade',       20);

# build just under the max ships the tester space port can hold
for ( 0 .. 2 ) {
    my $dory = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'dory'});
    $tester_shipyard->build_ship($dory);
}
$tester->finish_ships($tester_shipyard->id);

$trader->post('trade', 'get_glyphs', [$trader_session_id, $trader_trade->id]);
exit;


# build some ships for the trader to trade

my @ships;
for ( 0 .. 7 ) {
    my $dory = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'dory'});
    $trader_shipyard->build_ship($dory);
    push @ships, $dory;
}
my $freighter = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'freighter'});
$trader_shipyard->build_ship($freighter);

$trader->finish_ships($trader_shipyard->id);

# Trader puts 4 ships on the Trade ministry
my $result = $trader->post('trade', 'add_to_market', [$trader_session_id, $trader_trade->id, [
    { type => 'ship', ship_id => $ships[0]->id},
    { type => 'ship', ship_id => $ships[1]->id},
    { type => 'ship', ship_id => $ships[2]->id},
    { type => 'ship', ship_id => $ships[3]->id},
], 1, { ship_id => $freighter->id}]);
my $trade_trade_id = $result->{result}{trade_id};
ok($trade_trade_id, 'there is a trade on the Trade Ministry');

# Trader puts 4 ships on the SST
$result = $trader->post('transporter', 'add_to_market', [$trader_session_id, $trader_transporter->id, [
    { type => 'ship', ship_id => $ships[4]->id},
    { type => 'ship', ship_id => $ships[5]->id},
    { type => 'ship', ship_id => $ships[6]->id},
    { type => 'ship', ship_id => $ships[7]->id},
], 1]);
my $transporter_trade_id = $result->{result}{trade_id};
ok($transporter_trade_id, 'there is a trade on the Transporter');

Lacuna->cache->set('captcha', $tester_session_id, { guid => 1111, solution => 1111 }, 60 * 15 );
$tester->post('captcha', 'solve', [$tester_session_id, 1111, 1111]);

$result = $tester->post('transporter', 'accept_from_market', [$tester_session_id, $tester_transporter->id, $transporter_trade_id]);
is($result->{error}{code}, 1009, 'Cannot accept more ships than the space port can accept via Transporter');

$result = $tester->post('trade', 'accept_from_market', [$tester_session_id, $tester_trade->id, $trade_trade_id]);
is($result->{error}{code}, 1009, 'Cannot accept more ships than he space port can accept via Trade');






END {
#    TestHelper->clear_all_test_empires;
}
