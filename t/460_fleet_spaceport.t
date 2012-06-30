use lib '../lib';

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;

use TestHelper;

#TestHelper->clear_all_test_empires;
#diag("Cleared all test empires");

my $tester = TestHelper->new->use_existing_test_empire;
my $enemy  = TestHelper->new({empire_name => 'TLE Test Enemy'})->use_existing_test_empire;

my $test_session_id = $tester->session->id;
my $test_empire     = $tester->empire;
my $test_home       = $test_empire->home_planet;
my @test_planets    = $test_empire->planets;
my ($test_colony)   = grep {$_->id != $test_home->id} @test_planets;

my $result;

my $test_spaceport = $test_home->spaceport;

## spaceport - view
##
$result = $tester->post('spaceport','view', [{
    session_id  => $test_session_id, 
    building_id => $test_spaceport->id,
    no_status   => 1,
}]);
exit;
my $fleets = $test_home->fleets->search({
    task => 'Docked',
});
my $ships;
while (my $fleet = $fleets->next) {
    $ships->{$fleet->type} += $fleet->quantity;
}
foreach my $ship (sort keys %{$result->{result}{docked_ships}} ) {
    is($result->{result}{docked_ships}{$ship}, $ships->{$ship}, "Correct number of docked $ship");
}

## spaceport - view_all_fleets
##
$result = $tester->post('spaceport','view_all_fleets', [{
    session_id  => $test_session_id, 
    building_id => $test_spaceport->id, 
    paging      => {no_paging => 1},
    no_status   => 1,
}]);
$fleets = $test_home->fleets->search;
while (my $fleet = $fleets->next) {
    my ($result_fleet) = grep {$_->{id} == $fleet->id} @{$result->{result}{fleets}};
    ok($result_fleet, "Fleet (".$result_fleet->{details}{type}.") is in the results");
    is($result_fleet->{task},     $fleet->task, "Tasks are the same");
    is($result_fleet->{quantity}, $fleet->quantity, "Quantities are the same");
}
exit;

## spaceport - get_incoming_for
###      for our homeworld
$result = $tester->post('spaceport','get_incoming_for', [$test_session_id, {body_id => $test_home->id}, {no_paging => 1}]);

###      for our colony
$result = $tester->post('spaceport','get_incoming_for', [$test_session_id, {body_id => $test_colony->id}, {no_paging => 1}]);



## spaceport - view_incoming_fleets
##
$result = $tester->post('spaceport','view_incoming_fleets', [$test_session_id, $test_spaceport->id]);



done_testing;

END {
#    TestHelper->clear_all_test_empires;
}
