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
ok($result->{result}{building}{id}, "built an intelligence ministry");
my $intelligence = $tester->get_building($result->{result}{building}{id});
$intelligence->finish_upgrade;

$result = $tester->post('intelligence', 'view', [$session_id, $intelligence->id]);
is($result->{result}{spies}{maximum}, 1, "get spy data");

$result = $tester->post('intelligence', 'train_spy', [$session_id, $intelligence->id, 3]);
is($result->{result}{trained}, 1, "train a spy");

$result = $tester->post('intelligence', 'view_spies', [$session_id, $intelligence->id]);
is($result->{result}{spies}[0]{is_available}, 0, "spy training");
is($result->{result}{possible_assignments}[0], 'Idle', "possible assignments");
my $spy_id = $result->{result}{spies}[0]{id};

$result = $tester->post('intelligence', 'name_spy', [$session_id, $intelligence->id, $spy_id, 'Waldo']);
ok(exists $result->{result}, 'name spy seems to work');

$result = $tester->post('intelligence', 'view_spies', [$session_id, $intelligence->id]);
is($result->{result}{spies}[0]{name}, 'Waldo', "spy naming works");

$result = $tester->post('intelligence', 'burn_spy', [$session_id, $intelligence->id, $spy_id]);
ok(exists$result->{result}, "burn a spy");

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

######## NEED TO GIVE MYSELF 5 SPY PODS once the new ship system is in

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

$result = $tester->post('spaceport', 'view', [$session_id, $spaceport->id]);
is($result->{result}{docked_ships}{spy_pod}, 1, "we have 1 spy_pod built");

$result = $tester->post('spaceport', 'send_ship', [$session_id, $spy_pod->id, {body_name=>'Lacuna'}]);
is($result->{error}{code}, 1013, "leave isolationsts alone");

for my $count ( 1 .. 5 ) {
    Lacuna->db->resultset('Lacuna::DB::Result::Spies')->new({
        from_body_id    => $home->id,
        on_body_id      => $home->id,
        task            => 'Idle',
        available_on    => DateTime->now,
        empire_id       => $empire->id,    
    })->insert;
}

my $enemy = TestHelper->new(empire_name => 'TLE Test Enemy')->generate_test_empire->build_infrastructure;
$enemy->empire->is_isolationist(0);
$enemy->empire->update;

Lacuna->cache->set('captcha', $session_id, { guid => 1111, solution => 1111 }, 60 * 30 );

$result = $tester->post('spaceport', 'prepare_send_spies', [$session_id, $home->id, $enemy->empire->home_planet->id ]);
is( ref $result->{result}{spies}, 'ARRAY', "can prepare for send spies" );

my $spy_id = $result->{result}{spies}[0]{id};
$result = $tester->post('spaceport', 'send_spies', [$session_id, $home->id, $enemy->empire->home_planet->id, $spy_pod->id, [ $spy_id] ]);
ok($result->{result}{ship}{date_arrives}, "spy pod sent");

END {
    TestHelper->clear_all_test_empires;
}
