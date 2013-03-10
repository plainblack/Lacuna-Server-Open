use lib '../lib';

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Data::Dumper::Perltidy;
use 5.010;
use DateTime;

use TestHelper;

#TestHelper->clear_all_test_empires;
#diag("Cleared all test empires");

my $tester = TestHelper->new->use_existing_test_empire;
#my $enemy  = TestHelper->new({empire_name => 'TLE Test Enemy'})->use_existing_test_empire;

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
#$result = $tester->post('spaceport','view', [{
#    session_id  => $test_session_id,
#    building_id => $test_spaceport->id,
#}]);
#ok($result->{result}{docked_ships}, "Has docked ships");
#ok($result->{result}{docked_ships}{sweeper} > 1000, "Has sweepers");

$result = $tester->post('spaceport','view_all_fleets', [{
    session_id  => $test_session_id, 
    building_id => $test_spaceport->id, 
    paging      => {no_paging => 1},
    no_status   => 1,
}]);
exit;

my ($sweepers) = grep {$_->{details}{type} eq 'sweeper'} @{$result->{result}{fleets}};
ok($sweepers->{quantity} > 1000, "view_all_fleets sweepers");

$result = $tester->post('spaceport','view_incoming_fleets', [{
    session_id  => $test_session_id,
    paging      => {no_paging => 1},
    target      => { body_id => $test_home->id},
    no_status   => 1,
}]);
ok($result->{result}{incoming}, "Has incoming");

$result = $tester->post('spaceport','view_available_fleets', [{
    session_id  => $test_session_id,
    body_id     => $test_home->id,
    target      => { body_id => $test_home->id},
    no_status   => 1,
}]);
exit;

my @available = @{$result->{result}{available}};
#for my $fleet (@available) {
#    diag "Available [".$fleet->{id}."][".$fleet->{details}{type}."][".$fleet->{quantity}."]\n";
#    diag Dumper $fleet->{earliest_arrival};
#}
my $fleet = $available[0];
diag "Available [".$fleet->{id}."][".$fleet->{details}{type}."][".$fleet->{quantity}."]\n";
diag Dumper $fleet->{earliest_arrival};

$result = $tester->post('spaceport','send_fleet', [{
    session_id  => $test_session_id,
    fleet_id    => $fleet->{id},
    quantity    => 1,
    target      => { body_id => $test_home->id},
    arrival_date    => {
        month   => 1,
        date    => 1,
        hour    => 0,
        minute  => 0,
        second  => 0,
    },
    no_status   => 1,
}]);                

$result = $tester->post('spaceport','view_travelling_fleets', [{
    session_id  => $test_session_id,
    building_id => $test_spaceport->id,
    no_status   => 1,
}]);

$fleets = $test_home->fleets->search({
    task => 'Defend',
});
while (my $fleet = $fleets->next) {
    diag "Fleet defending [".$fleet->id."]";
    $result = $tester->post('spaceport','recall_fleet', [{
        session_id  => $test_session_id,
        fleet_id    => $fleet->id,
        quantity    => 1,
        no_status   => 1,
    }]);
    last;
}

$result = $tester->post('spaceport','view_unavailable_fleets', [{
    session_id  => $test_session_id,
    body_id     => $test_home->id,
    target      => { body_id => $test_home->id},
    no_status   => 1,
}]);

my @unavailable = @{$result->{result}{unavailable}};
for my $fleet (@unavailable) {
    diag "Unavailable [".$fleet->{id}."][".$fleet->{details}{type}."][".$fleet->{quantity}."][".$fleet->{reason}."]\n";
    #diag Dumper $fleet;
}

$result = $tester->post('spaceport','view_orbiting_fleets', [{
    session_id  => $test_session_id,
    target      => { body_id => $test_home->id},
}]);

$result = $tester->post('spaceport','view_all_fleets', [{
    session_id  => $test_session_id,
    building_id => $test_spaceport->id,
    no_status   => 1,
}]);
my @fleets = @{$result->{result}{fleets}};
($fleet) = grep {$_->{details}{can_scuttle}} @fleets;

diag "Can scuttle [".$fleet->{details}{type}."]";

$result = $tester->post('spaceport','scuttle_fleet', [{
    session_id  => $test_session_id,
    building_id => $test_spaceport->id,
    fleet_id    => $fleet->{id},
}]);

$result = $tester->post('spaceport', 'prepare_send_spies', [{
    session_id  => $test_session_id,
    on_body_id  => $test_home->id,
    to_body     => { body_id => $test_home->id},
}]);

my $spy = $result->{result}{spies}[0];
$fleet = $result->{result}{fleets}[0];

diag(Dumper($spy));
diag(Dumper($fleet));

$result = $tester->post('spaceport', 'send_spies', [{
    session_id  => $test_session_id,
    on_body_id  => $test_home->id,
    to_body_id  => $test_home->id,
    fleet_id    => $fleet->{id},
    spy_ids     => [$spy->{id}],
}]);


exit;



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
