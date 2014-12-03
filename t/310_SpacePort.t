use lib '../lib';
use Test::More tests => 24;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;

use TestHelper;

TestHelper->clear_all_test_empires;

my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;
my $command = $home->command;


my $result;


my $uni = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => -1,
    class           => 'Lacuna::DB::Result::Building::University',
    level           => 2,
});
$home->build_building($uni);
$uni->finish_upgrade;

$home->ore_hour(5000);
$home->water_hour(5000);
$home->energy_hour(5000);
$home->algae_production_hour(5000);
$home->ore_capacity(5000);
$home->energy_capacity(5000);
$home->food_capacity(5000);
$home->water_capacity(5000);
$home->bauxite_stored(5000);
$home->algae_stored(5000);
$home->energy_stored(5000);
$home->water_stored(5000);
$home->needs_recalc(0);
$home->update;

$empire->is_isolationist(0);
$empire->update;

my $enemy = TestHelper->new(empire_name => 'TLE Test Enemy')->generate_test_empire->build_infrastructure;
$enemy->empire->is_isolationist(0);
$enemy->empire->update;

$result = $tester->post('spaceport', 'build', [$session_id, $home->id, 0, 1]);
ok($result->{result}{building}{id}, "built a space port");
my $spaceport = $tester->get_building($result->{result}{building}{id});
$spaceport->finish_upgrade;

$result = $tester->post('spaceport', 'view', [$session_id, $spaceport->id]);
ok(exists $result->{result}{docked_ships}, "can see docked ships");

$result = $tester->post('spaceport', 'view_ships_travelling', [$session_id, $spaceport->id]);
is(ref $result->{result}{ships_travelling}, 'ARRAY', "can see travelling ships");

$result = $tester->post('spaceport', 'view_all_ships', [$session_id, $spaceport->id]);
is(ref $result->{result}{ships}, 'ARRAY', "can see all my ships");

$result = $tester->post('spaceport', 'view_foreign_ships', [$session_id, $spaceport->id]);
is(ref $result->{result}{ships}, 'ARRAY', "can see all foreign ships");

$result = $tester->post('spaceport', 'get_ships_for', [$session_id, $home->id, { body_id => $enemy->empire->home_planet->id }]);
is(ref $result->{result}{available}, 'ARRAY', "can see what ships are available to send");
is(ref $result->{result}{orbiting}, 'ARRAY', "can see what ships are orbiting");

$result = $tester->post('spaceport', 'view_ships_orbiting', [$session_id, $spaceport->id]);
is(ref $result->{result}{ships}, 'ARRAY', "can see orbiting ships");

$result = $tester->post('spaceport', 'recall_all', [$session_id, $spaceport->id]);
is(ref $result->{result}{ships}, 'ARRAY', 'can call recall_all');

my $shipyard = Lacuna::db->resultset('Lacuna::DB::Result::Building')->new({
	x       => 0,
	y       => 2,
	class   => 'Lacuna::DB::Result::Building::Shipyard',
	level   => 20,
});
$home->build_building($shipyard);
$shipyard->finish_upgrade;

my $intelligence = Lacuna::db->resultset('Lacuna::DB::Result::Building')->new({
	x       => 0,
	y       => 3,
	class   => 'Lacuna::DB::Result::Building::Intelligence',
	level   => 20,
});
$home->build_building($intelligence);
$intelligence->finish_upgrade;

# need a spy done right now
Lacuna->db->resultset('Lacuna::DB::Result::Spies')->new({
    from_body_id    => $home->id,
    on_body_id      => $home->id,
    task            => 'Idle',
    available_on    => DateTime->now,
    empire_id       => $empire->id,
})->insert;

my @ships;
for my $i ( 0 .. 1 ) {
	my $sweeper = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'sweeper'});
	$shipyard->build_ship($sweeper);
	push @ships, $sweeper;
}
my $thud = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'thud'});
$shipyard->build_ship($thud);
push @ships, $thud;

my $sweeper = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'sweeper'});
$shipyard->build_ship($sweeper);

my $spy_pod = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'spy_pod'});
$shipyard->build_ship($spy_pod);

my $spy_shuttle = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'spy_shuttle'});
$shipyard->build_ship($spy_shuttle);

my $finish = DateTime->now;
Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({shipyard_id=>$shipyard->id})->update({date_available=>$finish});

$result = $tester->post('spaceport', 'view', [$session_id, $spaceport->id]);

@ships = map { $_->id } @ships;

$result = $tester->post('spaceport', 'prepare_send_spies', [$session_id, $home->id, $enemy->empire->home_planet->id ]);
is( $result->{error}{code}, 1016, 'prepare_send_spies requires a captcha.' );

$result = $tester->post('spaceport', 'send_fleet', [$session_id, [ @ships ], { body_id => $enemy->empire->home_planet->id } ] );
is( $result->{error}{code}, 1016, 'send_fleet requires a captcha.' );

Lacuna->cache->set('captcha', $session_id, { guid => 1111, solution => 1111 }, 60 * 30 );

ok( eval{ $tester->post('captcha','solve', [$session_id, 1111, 1111]) }, 'Solved captcha' );

$result = $tester->post('spaceport', 'prepare_send_spies', [$session_id, $home->id, $enemy->empire->home_planet->id ]);
is( ref $result->{result}{spies}, 'ARRAY', "can prepare for send spies" );

my $spy_id = $result->{result}{spies}[0]{id};
$result = $tester->post('spaceport', 'send_spies', [$session_id, $home->id, $enemy->empire->home_planet->id, $spy_pod->id, [ $spy_id ] ]);
ok($result->{result}{ship}{date_arrives}, "spy pod sent");

$spy_pod = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$spy_pod->id})->first; # pull the latest data on this ship
$spy_pod->arrive;
$spy = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search({id=>$spy_id})->first;
$spy->available_on($finish);
$spy->task('Idle');
$spy->update;

$result = $tester->post('spaceport', 'send_fleet', [$session_id, [ @ships ], { body_id => $enemy->empire->home_planet->id }, -100 ] );
is($result->{error}{code}, 1009, 'set_speed cannot be less than 0');

$result = $tester->post('spaceport', 'send_fleet', [$session_id, [ @ships ], { body_id => $enemy->empire->home_planet->id }, 99999 ] );
is($result->{error}{code}, 1009, 'set_speed exceeds speed of slowest ship');

$result = $tester->post('spaceport', 'send_fleet', [$session_id, [ @ships ], { body_id => $enemy->empire->home_planet->id } ] );
ok($result->{result}{fleet}[0]{ship}{date_arrives}, "fleet sent");

$result = $tester->post('spaceport', 'send_ship', [$session_id, $sweeper->id, { body_id => $enemy->empire->home_planet->id } ] );
ok($result->{result}{ship}{date_arrives}, "sweeper sent");

# need some spies done right now
for my $count ( 1 .. 4 ) {
    Lacuna->db->resultset('Lacuna::DB::Result::Spies')->new({
        from_body_id    => $home->id,
        on_body_id      => $home->id,
        task            => 'Idle',
        available_on    => DateTime->now,
        empire_id       => $empire->id,
    })->insert;
}

$result = $tester->post('spaceport', 'prepare_send_spies', [$session_id, $home->id, $enemy->empire->home_planet->id ]);
my $spies = $result->{result}{spies};
@$spies = map { $_->{id} } @$spies;

$result = $tester->post('spaceport', 'send_spies', [$session_id, $home->id, $enemy->empire->home_planet->id, $spy_shuttle->id, $spies ] );
ok($result->{result}{ship}{date_arrives}, "spy shuttle sent to orbit");

$spy_shuttle = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$spy_shuttle->id})->first; # pull the latest data on this ship
$spy_shuttle->arrive;

$spy_shuttle = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$spy_shuttle->id})->first; # pull the latest data on this ship

for my $spy_id ( @$spies ) {
    $spy = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search({id=>$spy_id})->first;
    $spy->available_on($finish);
    $spy->task('Idle');
    $spy->update;
}

$result = $tester->post('spaceport', 'get_ships_for', [$session_id, $home->id, { body_id => $enemy->empire->home_planet->id }]);
is(ref $result->{result}{orbiting}, 'ARRAY', "can see what ships are available to recall");

$result = $tester->post('spaceport', 'prepare_fetch_spies', [$session_id, $enemy->empire->home_planet->id, $home->id ]);
is( ref $result->{result}{ships}, 'ARRAY', "can prepare for fetch spies");

$spy_shuttle = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$spy_shuttle->id})->first; # pull the latest data on this ship
$result = $tester->post('spaceport', 'recall_ship', [$session_id, $spaceport->id, $spy_shuttle->id]);
ok($result->{result}{ship}{date_arrives}, "spy shuttle recalled");
$spy_shuttle = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$spy_shuttle->id})->first; # pull the latest data on this ship
$spy_shuttle->arrive;

$result = $tester->post('spaceport', 'view_all_ships', 
    [$session_id, $spaceport->id, undef, { task => "Docked", tag => [qw(Trade Mining)]}, 'combat']
);
is(ref $result->{result}{ships}, 'ARRAY', "view_all_ships with default paging and filter options work");

$result = $tester->post('spaceport', 'view_all_ships', 
    [$session_id, $spaceport->id, { no_paging => 1}, { task => "Docked", tag => [qw(Trade Mining)]}, 'combat']
);
is(ref $result->{result}{ships}, 'ARRAY', "view_all_ships with no paging and filter options work");


END {
    TestHelper->clear_all_test_empires;
}
