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

my $tester          = TestHelper->new->use_existing_test_empire;
my $test_session_id = $tester->session->id;
my $test_empire     = $tester->empire;
my $test_home       = $test_empire->home_planet;
my @test_planets    = $test_empire->planets;
my ($test_colony)   = grep {$_->id != $test_home->id} @test_planets;

my $result;

my $test_shipyard   = $test_home->shipyard;

# remove some ships so we know we have space to build more
my ($fleet) = $test_home->fleets->search({ task => 'Docked'},{ order_by => { -desc => 'quantity'}});
my $fleet_type = 'sweeper';
my $fleet_quantity = '20';
if ($fleet) {
    diag("Deleting ".$fleet->quantity." ships of type ".$fleet->type);
    $fleet_type     = $fleet->type;
    $fleet->delete;
};

$result = $tester->post('shipyard','view', [{
    session_id  => $test_session_id,
    building_id => $test_shipyard->id,
    no_status   => 1,
}]);

$result = $tester->post('shipyard', 'view_build_queue', [{
    session_id  => $test_session_id, 
    building_id => $test_shipyard->id,
    no_status   => 1,
}]);

$result = $tester->post('shipyard', 'subsidize_build_queue', [{
    session_id  => $test_session_id, 
    building_id => $test_shipyard->id,
    no_status   => 1,
}]);

$result = $tester->post('shipyard', 'get_buildable', [{
    session_id  => $test_session_id, 
    building_id => $test_shipyard->id,
    no_status   => 1,
}]);

$result = $tester->post('shipyard', 'get_buildable', [{
    session_id  => $test_session_id, 
    building_id => $test_shipyard->id, 
    tag         => 'Trade',
    no_status   => 1,
}]);

$result = $tester->post('shipyard', 'get_buildable', [
    $test_session_id,
    $test_shipyard->id,
    "Trade",
]);

$result = $tester->post('shipyard', 'build_fleet', [{
    session_id  => $test_session_id,
    building_id => $test_shipyard->id,
    type        => $fleet_type,
    quantity    => $fleet_quantity,
    no_status   => 1,
}]);
is($result->{result}{number_of_fleets_building}, 1, "One fleet building");

$result = $tester->post('shipyard', 'subsidize_build_queue', [{
    session_id  => $test_session_id,
    building_id => $test_shipyard->id,
    no_status   => 1,
}]);
            
done_testing;

END {
#    TestHelper->clear_all_test_empires;
}
