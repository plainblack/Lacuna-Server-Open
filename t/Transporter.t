use lib '../lib';
use Test::More tests => 18;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;

use TestHelper;
my $tester = TestHelper->new->generate_test_empire->build_infrastructure;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
$empire->add_essentia(100,'testing transporter')->update;
my $home = $empire->home_planet;

my $result;


$result = $tester->post('transporter', 'build', [$session_id, $home->id, 0, 3]);
ok($result->{result}{building}{id}, "built a transporter");
my $transporter = $tester->get_building($result->{result}{building}{id});
$transporter->finish_upgrade;

$result = $tester->post('transporter', 'view_my_trades', [$session_id, $transporter->id]);
ok(exists $result->{result}, 'can call view_my_trades');

$result = $tester->post('transporter', 'get_stored_resources', [$session_id, $transporter->id]);
ok(exists $result->{result}, 'can call get_stored_resources');

$result = $tester->post('transporter', 'view_available_trades', [$session_id, $transporter->id]);
ok(exists $result->{result}, 'can call view_available_trades');

$result = $tester->post('transporter', 'get_ships', [$session_id, $transporter->id]);
ok(exists $result->{result}, 'can call get_ships');

$result = $tester->post('transporter', 'get_prisoners', [$session_id, $transporter->id]);
ok(exists $result->{result}, 'can call get_prisoners');

$result = $tester->post('transporter', 'get_plans', [$session_id, $transporter->id]);
ok(exists $result->{result}, 'can call get_plans');

$result = $tester->post('transporter', 'get_glyphs', [$session_id, $transporter->id]);
ok(exists $result->{result}, 'can call get_glyphs');

$result = $tester->post('transporter', 'add_trade', [$session_id, $transporter->id]); # no ships
is($result->{error}{code}, 1013, 'can call add_trade');

$result = $tester->post('transporter', 'accept_trade', [$session_id, $transporter->id]);
is($result->{error}{code}, 1002, 'can call accept_trade');

$result = $tester->post('transporter', 'withdraw_trade', [$session_id, $transporter->id]);
is($result->{error}{code}, 1002, 'can call withdraw_trade');

$result = $tester->post('transporter', 'push_items', [$session_id, $transporter->id]);
is($result->{error}{code}, 1002, 'can call push_items');

$result = $tester->post('transporter', 'trade_one_for_one', [$session_id, $transporter->id, 'algae', 'energy', 10]);
ok(exists $result->{result}, 'can call trade_one_for_one');


$result = $tester->post('transporter', 'add_to_market', [$session_id, $transporter->id, [{ type => 'algae', quantity => 100000}], 1]); 
is($result->{error}{code}, 1011, 'can call add_to_market');

$result = $tester->post('transporter', 'accept_from_market', [$session_id, $transporter->id]); # no trade specified
is($result->{error}{code}, 1002, 'can call accept_from_market');

$result = $tester->post('transporter', 'withdraw_from_market', [$session_id, $transporter->id]); # no trade specified
is($result->{error}{code}, 1002, 'can call withdraw_from_market');

$result = $tester->post('transporter', 'view_market', [$session_id, $transporter->id]);
is(scalar @{$result->{result}{trades}}, 0, 'can call view_market');

$result = $tester->post('transporter', 'view_my_market', [$session_id, $transporter->id]);
is(scalar @{$result->{result}{trades}}, 0, 'can call view_my_market');


END {
    $tester->cleanup;
}
