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

$result = $tester->post('shipyard','view', [{
    session     => $test_session_id,
    building    => $test_shipyard->id,
    no_status   => 1,
}]);

$result = $tester->post('shipyard', 'view_build_queue', [{
    session     => $test_session_id, 
    building    => $test_shipyard->id,
    no_status   => 1,
}]);

$result = $tester->post('shipyard', 'subsidize_build_queue', [{
    session     => $test_session_id, 
    building    => $test_shipyard->id,
    no_status   => 1,
}]);

$result = $tester->post('shipyard', 'get_buildable', [{
    session     => $test_session_id, 
    building    => $test_shipyard->id,
    no_status   => 1,
}]);

$result = $tester->post('shipyard', 'get_buildable', [{
    session     => $test_session_id, 
    building    => $test_shipyard->id, 
    tag         => 'Trade',
    no_status   => 1,
}]);

#$result = $tester->post('spaceport','view', [$test_session_id, $test_spaceport->id]);


done_testing;

END {
#    TestHelper->clear_all_test_empires;
}
