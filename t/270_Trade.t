use lib '../lib';
use Test::More tests => 12;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;

use TestHelper;
TestHelper->clear_all_test_empires;

my $tester = TestHelper->new->generate_test_empire->build_infrastructure;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;

my $result;


$result = $tester->post('spaceport', 'build', [$session_id, $home->id, 0, 1]);
my $spaceport = $tester->get_building($result->{result}{building}{id});
$spaceport->finish_upgrade;

$result = $tester->post('shipyard', 'build', [$session_id, $home->id, 0, 2]);
my $shipyard = $tester->get_building($result->{result}{building}{id});
$shipyard->finish_upgrade;

$result = $tester->post('trade', 'build', [$session_id, $home->id, 0, 3]);
ok($result->{result}{building}{id}, "built a trade ministry");
my $trade = $tester->get_building($result->{result}{building}{id});
$trade->finish_upgrade;

$result = $tester->post('trade', 'get_trade_ships', [$session_id, $trade->id]);
ok(exists $result->{result}, 'can call get_trade_ships');

$result = $tester->post('trade', 'get_ships', [$session_id, $trade->id]);
ok(exists $result->{result}, 'can call get_ships');

$result = $tester->post('trade', 'get_prisoners', [$session_id, $trade->id]);
ok(exists $result->{result}, 'can call get_prisoners');

$result = $tester->post('trade', 'get_plans', [$session_id, $trade->id]);
ok(exists $result->{result}, 'can call get_plans');

$result = $tester->post('trade', 'get_glyphs', [$session_id, $trade->id]);
ok(exists $result->{result}, 'can call get_glyphs');

$result = $tester->post('trade', 'push_items', [$session_id, $trade->id]);
is($result->{error}{code}, 1002, 'can call push_items');

$result = $tester->post('trade', 'add_to_market', [$session_id, $trade->id, [{ type => 'algae', quantity => 100000}], 1]); 
is($result->{error}{code}, 1011, 'can call add_to_market');

$result = $tester->post('trade', 'accept_from_market', [$session_id, $trade->id]); # no trade specified
is($result->{error}{code}, 1002, 'can call accept_from_market');

$result = $tester->post('trade', 'withdraw_from_market', [$session_id, $trade->id]); # no trade specified
is($result->{error}{code}, 1002, 'can call withdraw_from_market');

$result = $tester->post('trade', 'view_market', [$session_id, $trade->id]);
is(scalar @{$result->{result}{trades}}, 0, 'can call view_market');

$result = $tester->post('trade', 'view_my_market', [$session_id, $trade->id]);
is(scalar @{$result->{result}{trades}}, 0, 'can call view_my_market');



END {
    TestHelper->clear_all_test_empires;
}
