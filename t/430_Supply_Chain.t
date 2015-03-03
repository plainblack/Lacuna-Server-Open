use lib '../lib';

use strict;
use warnings;

use Test::More tests => 10;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;

use TestHelper;
my $tester = TestHelper->new->use_existing_test_empire;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;
my $command = $home->command;

my $result;

diag("Create a station");

my $station = Lacuna->db->resultset('Map::Body')->search({
    class => 'Lacuna::DB::Result::Map::Body::Planet::Station',
    empire_id => $empire->id,
    })->first;

if (not $station) {
    $station = Lacuna->db->resultset('Map::Body')->search({
        class => {like => 'Lacuna::DB::Result::Map::Body::Planet::P%'},
        empire_id => undef,
        })->first;

    $station->convert_to_station($empire);
    $station = $station->discard_changes; # just in case
    $station->alliance_id($empire->alliance_id);
    $station->update;
}

# make sure the station has resources
$station->apple_stored(4500);
$station->water_stored(4500);
$station->energy_stored(4500);
$station->gold_stored(4500);
$station->update;
$station->tick;

my $trade = Lacuna->db->resultset('Building')->search({
    class => 'Lacuna::DB::Result::Building::Trade',
    body_id => $home->id,
    })->first;

# remove any existing ships from the supply chain
$result = $tester->post('trade','get_supply_ships', [$session_id, $trade->id]);
my @ship_ids = map {$_->{id} } grep {$_->{task} eq 'Supply Chain'} @{$result->{result}{ships}};
foreach my $ship_id ( @ship_ids ) {
    diag "### remove ship [$ship_id] ###";
    $result = $tester->post('trade', 'remove_supply_ship_from_fleet', [$session_id, $trade->id, $ship_id]);
}

# remove any existing supply chains
$result = $tester->post('trade','view_supply_chains', [$session_id, $trade->id]);
my @chain_ids = map {$_->{id} } @{$result->{result}{supply_chains}};
foreach my $chain_id (@chain_ids) {
    diag "Remove supply chain [$chain_id]";
    $result = $tester->post('trade', 'delete_supply_chain', [$session_id, $trade->id, $chain_id]);
}

# Determine the current resource production of the SS
$result = $tester->post('body','get_status', [$session_id, $station->id]);
my $ore_hour    = $result->{result}{body}{ore_hour};
my $water_hour  = $result->{result}{body}{water_hour};
my $energy_hour = $result->{result}{body}{energy_hour};
my $food_hour   = $result->{result}{body}{food_hour};
diag "ore_hour=[$ore_hour] water_hour=[$water_hour] energy_hour=[$energy_hour] food_hour=[$food_hour]";

# Create supply chains to the SS
$result = $tester->post('trade','create_supply_chain',[$session_id, $trade->id, $station->id, 'water', -$water_hour]);
$result = $tester->post('trade','create_supply_chain',[$session_id, $trade->id, $station->id, 'trona', -$ore_hour]);
$result = $tester->post('trade','create_supply_chain',[$session_id, $trade->id, $station->id, 'energy',-$energy_hour]);
$result = $tester->post('trade','create_supply_chain',[$session_id, $trade->id, $station->id, 'algae', -$food_hour]);

my $supply_chains;
my @chains = @{$result->{result}{supply_chains}};
foreach my $chain (@chains) {
    $supply_chains->{$chain->{resource_type}} = $chain->{id};
}

# get a single ships to add to the supply chain
$result = $tester->post('trade','get_supply_ships', [$session_id, $trade->id]);
my ($ship_id) = map {$_->{id} } grep {$_->{task} eq 'Docked' and $_->{type} eq 'hulk'} @{$result->{result}{ships}};
diag("Ship [$ship_id]");
ok($ship_id, "We have a ship");

$result = $tester->post('trade','add_supply_ship_to_fleet',[$session_id, $trade->id, $ship_id]);
is(1, 1, "Added a ship to the fleet");

# Check the status of the supply chain
$result = $tester->post('trade','view_supply_chains', [$session_id, $trade->id]);
my @chains = @{$result->{result}{supply_chains}};
foreach my $chain (@chains) {
    cmp_ok($chain->{percent_transferred}, ">=", 100, "Transfer enough ".$chain->{resource_type});
}

# check that the station is at equilibrium
$result = $tester->post('body','get_status', [$session_id, $station->id]);
is($result->{result}{body}{ore_hour}, 0, "Zero ore");
is($result->{result}{body}{water_hour}, 0, "Zero water");
is($result->{result}{body}{energy_hour}, 0, "Zero energy");
is($result->{result}{body}{food_hour}, 0, "Zero food");

# modify a supply chain
$result = $tester->post('trade','update_supply_chain', [$session_id, $trade->id, $supply_chains->{water}, 'energy', 100]);

END {
#    TestHelper->clear_all_test_empires;
}
