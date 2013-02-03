use lib '..','../../lib';
use Test::More tests => 2;
use Test::Deep;
use 5.010;

use strict;
use warnings;

use Lacuna::Util qw(randint);
use Lacuna::Constants qw(ORE_TYPES);

use TestHelper;
TestHelper->clear_all_test_empires;

# Feature. Make it possible to select a quantity of plans or glyphs all of the same type for a trade

my $tester = TestHelper->new({ big_producer => 1 })->generate_test_empire->build_infrastructure;
my $tester_session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;
$empire->add_essentia({ amount => 100, reason => 'testing transporter'});
$empire->update;

# Build an SST and a space port

my $tester_spaceport   = $tester->build_building('Lacuna::DB::Result::Building::SpacePort',   2);
my $tester_shipyard    = $tester->build_building('Lacuna::DB::Result::Building::Shipyard',    2);
my $tester_transporter = $tester->build_building('Lacuna::DB::Result::Building::Transporter', 20);
my $tester_trade       = $tester->build_building('Lacuna::DB::Result::Building::Trade',       20);

my $tester_trade_id = $tester_trade->id;
diag "trade min ID = ".$tester_trade_id;

# build some glyphs and some plans that we can trade
#
my @ore_types = (ORE_TYPES);
my @plan_types = qw(SpacePort Shipyard Transporter Trade);
my $tester_home = $tester->empire->home_planet;

for ( 0 .. 10 ) {
    $tester_home->add_glyph('rutile');
    $tester_home->add_plan('Lacuna::DB::Result::Building::Food::Malcud', 1,3);
}

for ( 0 .. 15 ) {
    $tester_home->add_glyph('gold');
    $tester_home->add_plan('Lacuna::DB::Result::Building::Trade', 2);
}

# Build ships so we can trade
for ( 0 .. 2 ) {
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'hulk'});
    $tester_shipyard->build_ship($ship);
}
$tester->finish_ships($tester_shipyard->id);
$home->tick;

my $result = $tester->post('trade', 'get_glyph_summary', [$tester_session_id, $tester_trade_id]);
is_deeply


exit;

$result = $tester->post('trade', 'add_to_market', [$tester_session_id, $tester_trade_id, [
    {
        type        => 'glyph',
        name        => 'rutile',
        quantity    => 33,
    },
    ], 99]);
$result = $tester->post('trade', 'add_to_market', [$tester_session_id, $tester_trade_id, [
    {
        type        => 'glyph',
        name        => 'rutile',
        quantity    => 10,
    },
    ], 99]);

$result = $tester->post('trade', 'get_plan_summary', [$tester_session_id, $tester_trade_id]);

$result = $tester->post('trade', 'add_to_market', [$tester_session_id, $tester_trade_id, [
    {
        type        => 'plan',
        plan_class  => 'Lacuna::DB::Result::Building::Food::Malcud',
        level       => 1,
        extra_build_level => 3,
        quantity    => 3,
    },
    ], 99]);


END {
#    TestHelper->clear_all_test_empires;
}
