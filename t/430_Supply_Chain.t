use lib '../lib';

use strict;
use warnings;

use Test::More tests => 25;
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
    },{
    rows=>1,
})->single;

if (not $station) {
    $station = Lacuna->db->resultset('Map::Body')->search({
        class => {like => 'Lacuna::DB::Result::Map::Body::Planet::P%'},
        empire_id => undef,
        },{
        rows=>1,
    })->single;

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
    },{
    rows => 1,
})->single;

diag "Trade id =[".$trade->id."]";
$result = $tester->post('trade','get_supply_ships', [$session_id, $trade->id]);
#diag(Dumper($result->{result}{ships}));

# remove any existing ships from the supply chain
my @ship_ids = map {$_->{id} } grep {$_->{task} eq 'Supply Chain'} @{$result->{result}{ships}};
diag Dumper(\@ship_ids);

foreach my $ship_id ( @ship_ids ) {
    diag "### remove ship [$ship_id] ###";
    $result = $tester->post('trade', 'remove_supply_ship_from_fleet', [$session_id, $trade->id, $ship_id]);
}
exit;

# get a single ships to add to the supply chain
my ($ship_id) = map {$_->{id} } grep {$_->{task} eq 'Docked' and $_->{type} eq 'hulk'} @{$result->{result}{ships}};
diag("Ship [$ship_id]");
ok($ship_id, "We have a ship");

$result = $tester->post('trade','add_supply_ship_to_fleet',[$session_id, $trade->id, $ship_id]);
is(1, 1, "Added a ship to the fleet");



#my @temp = map { {task => $_->{task}, type => $_->{type} } } @{$result->{result}{ships}};
#my @comp = ({type=>'scow',task=>'Docked'},{type=>'scow_large',task=>'Docked'});
#cmp_deeply(\@comp,\@temp, "All ships docked");
#
#



END {
#    TestHelper->clear_all_test_empires;
}
