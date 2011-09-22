use lib '..','../../lib';
use Test::More tests => 2;
use Test::Deep;
use 5.010;

use strict;
use warnings;

use TestHelper;
TestHelper->clear_all_test_empires;

# BUG Building a Munitions does not break isolationism

my $tester = TestHelper->new({ big_producer => 1 })->generate_test_empire->build_infrastructure;
my $tester_session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;

$tester->find_empty_plot;
my $result = $tester->post('munitionslab', 'build', [$tester_session_id, $home->id, $tester->x, $tester->y]);
my $munitions = $tester->get_building($result->{result}{building}{id});
$munitions->finish_upgrade;
$home->tick;

$empire->discard_changes;

is($empire->is_isolationist, 0, 'Empire is now isolationist after building munitions');

$empire->is_isolationist(1);
$empire->update;

$tester->find_empty_plot;
$result = $tester->post('intelligence', 'build', [$tester_session_id, $home->id, $tester->x, $tester->y]);
my $intelligence = $tester->get_building($result->{result}{building}{id});
$intelligence->finish_upgrade;

$tester->find_empty_plot;
$result = $tester->post('espionage', 'build', [$tester_session_id, $home->id, $tester->x, $tester->y]);
my $espionage = $tester->get_building($result->{result}{building}{id});
$espionage->finish_upgrade;
$home->tick;

$empire->discard_changes;

is($empire->is_isolationist, 0, 'Empire is now isolationist after building espionage');


END {
#    TestHelper->clear_all_test_empires;
}
