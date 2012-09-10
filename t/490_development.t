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

my $tester = TestHelper->new->use_existing_test_empire;

my $test_session_id = $tester->session->id;
my $test_empire     = $tester->empire;
my $test_home       = $test_empire->home_planet;
my @test_planets    = $test_empire->planets;

my $result;
my $spaceport       = $test_home->spaceport;
my $development     = $test_home->development;

## Development - view - Positional arguments
##
$result = $tester->post('development','view', [$test_session_id, $development->id]);
# The build queue should be empty

my $build_queue = $result->{result}{build_queue};
is(scalar @$build_queue, 0, "Build queue is empty");

# Knock the spaceport down a level so we can upgrade it
if ($spaceport->level > 1) {
    $spaceport->level($spaceport->level - 1);
    $spaceport->update;
}

$result = $tester->post('spaceport','upgrade', [$test_session_id, $spaceport->id]);

$result = $tester->post('development','view', [$test_session_id, $development->id]);

$result = $tester->post('development','subsidize_build_queue', [$test_session_id, $development->id]);
ok($result->{result}{essentia_spent} > 0, "Essentia spent");

## Now with named arguments

$result = $tester->post('development','view', [{ session_id => $test_session_id, building_id => $development->id}]);
# The build queue should be empty

$build_queue = $result->{result}{build_queue};
is(scalar @$build_queue, 0, "Build queue is empty");

# Knock the spaceport down a level so we can upgrade it
if ($spaceport->level > 1) {
    $spaceport->level($spaceport->level - 1);
    $spaceport->update;
}

$result = $tester->post('spaceport','upgrade', [{ session_id => $test_session_id, building_id => $spaceport->id}]);

$result = $tester->post('development','view', [{
    session_id  => $test_session_id, 
    building_id => $development->id,
    no_status   => 1,
}]);

$result = $tester->post('development','subsidize_build_queue', [{ session_id => $test_session_id, building_id => $development->id }]);
ok($result->{result}{essentia_spent} > 0, "Essentia spent");

$result = $tester->post('development','view', [{
    session_id  => $test_session_id, 
    building_id => $development->id,
    no_status   => 1,
}]);


done_testing;

END {
#    TestHelper->clear_all_test_empires;
}
