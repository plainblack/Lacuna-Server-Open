use lib '../lib';
use Test::More tests => 15;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;

use TestHelper;
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

$result = $tester->post('spaceport', 'get_ships_for', [$session_id, $home->id, { body_id => $home->id }]);
is(ref $result->{result}{available}, 'ARRAY', "can see what ships are available to send");
is(ref $result->{result}{recallable}, 'ARRAY', "can see what ships are available to recall");

$empire->is_isolationist(0);
$empire->update;

my $shipyard = Lacuna::db->resultset('Lacuna::DB::Result::Building')->new({
	x       => 0,
	y       => 2,
	class   => 'Lacuna::DB::Result::Building::Shipyard',
	level   => 20,
});
$home->build_building($shipyard);
$shipyard->finish_upgrade;

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

my $finish = DateTime->now;
Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({shipyard_id=>$shipyard->id})->update({date_available=>$finish});

$result = $tester->post('spaceport', 'view', [$session_id, $spaceport->id]);

my $enemy = TestHelper->new(empire_name => 'Enemy')->generate_test_empire->build_infrastructure;
$enemy->empire->is_isolationist(0);
$enemy->empire->update;

@ships = map { $_->id } @ships;
diag explain @ships;

$result = $tester->post('spaceport', 'prepare_send_spies', [$session_id, $home->id, $home->id ]);
is( $result->{error}{code}, 1016, 'Needs to solve a captcha.' );

$result = $tester->post('spaceport', 'send_fleet', [$session_id, [ @ships ], { body_id => $enemy->empire->home_planet->id } ] );
is( $result->{error}{code}, 1016, 'Needs to solve a captcha.' );

Lacuna->cache->set('captcha', $session_id, { guid => 1111, solution => 1111 }, 60 * 30 );

ok( eval{ $tester->post('captcha','solve', [$session_id, 1111, 1111]) }, 'Solved captcha' );

$result = $tester->post('spaceport', 'prepare_send_spies', [$session_id, $home->id, $home->id ]);
is( ref $result->{result}{spies}, 'ARRAY', "can prepare for send spies" );

$result = $tester->post('spaceport', 'prepare_fetch_spies', [$session_id, $home->id, $home->id ]);
is( ref $result->{result}{ships}, 'ARRAY', "can prepare for fetch spies");

$result = $tester->post('spaceport', 'send_fleet', [$session_id, [ @ships ], { body_id => $enemy->empire->home_planet->id } ] );
ok($result->{result}{fleet}[0]{ship}{date_arrives}, "fleet sent");

$result = $tester->post('spaceport', 'send_ship', [$session_id, $sweeper->id, { body_id => $enemy->empire->home_planet->id } ] );
ok($result->{result}{ship}{date_arrives}, "sweeper sent");

$result = $tester->post('spaceport', 'view_all_ships', 
    [$session_id, $spaceport->id, undef, undef, { task => "Docked", tags => [qw(Trade Mining)]}, 'combat']
);
is(ref $result->{result}{ships}, 'ARRAY', "can see all my ships");

END {
	$enemy->cleanup;
    $tester->cleanup;
}
