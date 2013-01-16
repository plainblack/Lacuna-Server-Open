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

Lacuna->cache->set('captcha', $session_id, { guid => 1111, solution => 1111 }, 60 * 30 );

my $result;

$result = $tester->post('captcha','solve', [$session_id, 1111, 1111]);

$result = $tester->post('intelligence', 'build', [$session_id, $home->id, 0, 1]);
my $intelligence = $tester->get_building($result->{result}{building}{id});
$intelligence->finish_upgrade;

my $shipyard = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 1,
    y               => 1,
    class           => 'Lacuna::DB::Result::Building::Shipyard',
    level           => 5,
});
$home->build_building($shipyard);
$shipyard->finish_upgrade;

my $spaceport = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 1,
    y               => 2,
    class           => 'Lacuna::DB::Result::Building::SpacePort',
    level           => 5,
});
$home->build_building($spaceport);
$spaceport->finish_upgrade;

# need a spy done right now
Lacuna->db->resultset('Lacuna::DB::Result::Spies')->new({
    from_body_id    => $home->id,
    on_body_id      => $home->id,
    task            => 'Idle',
    available_on    => DateTime->now,
    empire_id       => $empire->id,    
})->insert;

my $spy_pod = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'spy_pod'});
$shipyard->build_ship($spy_pod);

my $finish = DateTime->now;
Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({shipyard_id=>$shipyard->id})->update({date_available=>$finish});


$result = $tester->post('mercenariesguild', 'build', [$session_id, $home->id, 0, 3]);
ok($result->{result}{building}{id}, "built a mercenaries guild");
my $merc = $tester->get_building($result->{result}{building}{id});
$merc->finish_upgrade;

$result = $tester->post('mercenariesguild', 'get_trade_ships', [$session_id, $merc->id]);
ok(exists $result->{result}, 'can call get_trade_ships');

$result = $tester->post('mercenariesguild', 'get_spies', [$session_id, $merc->id]);
ok(exists $result->{result}, 'can call get_spies');
my $spy_id = $result->{result}{spies}[0]{id};
diag "spy_id: $spy_id";

$result = $tester->post('mercenariesguild', 'add_to_market', [$session_id, $merc->id, $spy_id, 1]); 
is($result->{error}{code}, 1011, 'can call add_to_market');
ok($result->{error}{message} =~ / 2\.9 essentia /, 'requires 2.9 essentia to add_to_market');

$empire->add_essentia({amount => 100, reason => 'Topping up'});
$empire->update();

$result = $tester->post('mercenariesguild', 'add_to_market', [$session_id, $merc->id, undef, 1]); 
is($result->{error}{code}, 1013, 'no spy offered');

$result = $tester->post('mercenariesguild', 'add_to_market', [$session_id, $merc->id, $spy_id, 1, $spy_pod->id]); 
my $trade_id = $result->{result}{trade_id};
ok($trade_id, 'spy offered');

$result = $tester->post('mercenariesguild', 'accept_from_market', [$session_id, $merc->id]); # no trade specified
is($result->{error}{code}, 1002, 'can call accept_from_market');

$result = $tester->post('mercenariesguild', 'view_my_market', [$session_id, $merc->id]);
is(scalar @{$result->{result}{trades}}, 1, 'view_my_market only shows one trade');

$result = $tester->post('mercenariesguild', 'withdraw_from_market', [$session_id, $merc->id, $trade_id]); # no trade specified
ok($result->{result}{status}, 'can call withdraw_from_market');

$result = $tester->post('mercenariesguild', 'view_market', [$session_id, $merc->id]);
is(scalar @{$result->{result}{trades}}, 0, 'view_market shows no trades');

$result = $tester->post('mercenariesguild', 'view_my_market', [$session_id, $merc->id]);
is(scalar @{$result->{result}{trades}}, 0, 'view_my_market shows no trades');

# this could use some more tests

END {
    TestHelper->clear_all_test_empires;
}
