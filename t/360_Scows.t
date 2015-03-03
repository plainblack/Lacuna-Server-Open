use lib '../lib';
use Test::More tests => 16;
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
    level           => 5,
});
$home->build_building($uni);
$uni->finish_upgrade;
$empire->university_level(5);
$empire->update;

my $seq = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => -2,
    class           => 'Lacuna::DB::Result::Building::Waste::Sequestration',
    level           => 5,
});
$home->build_building($seq);
$seq->finish_upgrade;

$home->ore_hour(5000);
$home->water_hour(5000);
$home->energy_hour(5000);
$home->algae_production_hour(5000);
$home->ore_capacity(5000);
$home->energy_capacity(5000);
$home->food_capacity(5000);
$home->water_capacity(5000);
$home->waste_capacity(8000);
$home->bauxite_stored(5000);
$home->algae_stored(5000);
$home->energy_stored(5000);
$home->water_stored(5000);
$home->waste_stored(8000);
$home->needs_recalc(0);
$home->update;

$empire->is_isolationist(0);
$empire->update;

$result = $tester->post('spaceport', 'build', [$session_id, $home->id, 0, 1]);
my $spaceport = $tester->get_building($result->{result}{building}{id});
$spaceport->finish_upgrade;

my $shipyard = Lacuna::db->resultset('Lacuna::DB::Result::Building')->new({
	x       => 0,
	y       => 2,
	class   => 'Lacuna::DB::Result::Building::Shipyard',
	level   => 20,
});
$home->build_building($shipyard);
$shipyard->finish_upgrade;

my $scow = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'scow'});
$shipyard->build_ship($scow);

my $scow2 = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'scow'});
$shipyard->build_ship($scow2);

my $scow3 = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'scow'});
$shipyard->build_ship($scow);

my $finish = DateTime->now;

Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({shipyard_id=>$shipyard->id})->update({date_available=>$finish});

$result = $tester->post('spaceport', 'view', [$session_id, $spaceport->id]);

my $enemy = TestHelper->new(empire_name => 'TLE Test Enemy')->generate_test_empire->build_infrastructure;
$enemy->empire->is_isolationist(0);
$enemy->empire->update;

Lacuna->cache->set('captcha', $session_id, { guid => 1111, solution => 1111 }, 60 * 30 );

$result = $tester->post('spaceport', 'send_ship', [$session_id, $scow->id, { star_id => $home->star_id } ] );
ok($result->{result}{ship}{date_arrives}, "scow sent to star id " . $home_star_id);
$scow = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$scow->id})->first; # pull the latest data on this ship

is( $scow->foreign_star_id, $home->star_id, 'scow is headed to the correct foreign star id' );
is( $scow->foreign_body_id, undef, 'scow does not have a foreign body id' );

$scow->arrive;
is( $scow->task, 'Travelling', 'scow is travelling' );
is( $scow->direction, 'in', 'scow is headed home' );

$scow = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$scow->id})->first; # pull the latest data on this ship
$scow->arrive;
is( $scow->task, 'Docked', 'scow is docked' );
cmp_deeply( $scow->payload, {}, 'no payload' );

$result = $tester->post('captcha','solve', [$session_id, 1111, 1111]);
is($result->{result}, 1, 'Solved captcha');

$result = $tester->post('spaceport', 'send_ship', [$session_id, $scow2->id, { body_id => $enemy->empire->home_planet->id } ] );
ok($result->{result}{ship}{date_arrives}, "scow sent to planet id " . $enemy->empire->home_planet->id);
$scow2 = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$scow2->id})->first; # pull the latest data on this ship

is( $scow2->foreign_star_id, undef, 'scow2 does not have a foreign star id' );
is( $scow2->foreign_body_id, $enemy->empire->home_planet->id, 'scow2 is headed to the correct foreign body id' );

$scow2->arrive;
$scow2 = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$scow2->id})->first; # pull the latest data on this ship

$result = $tester->post('spaceport', 'view', [$session_id, $spaceport->id]);
is( $result->{result}{status}{empire}{most_recent_message}{subject}, "Ship Shot Down", 'Ship Shot Down' );

is( $scow2, undef, 'scow2 is undef' );

my $scow3 = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'scow'});
$shipyard->build_ship($scow3);

my $scow4 = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'scow'});
$shipyard->build_ship($scow4);

$finish = DateTime->now;

Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({shipyard_id=>$shipyard->id})->update({date_available=>$finish});

$result = $tester->post('spaceport', 'view', [$session_id, $spaceport->id]);

$scow3 = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$scow3->id})->first; # pull the latest data on this ship
$scow4 = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$scow4->id})->first; # pull the latest data on this ship

$result = $tester->post('spaceport', 'send_fleet', [$session_id, [$scow3->id, $scow4->id], { star_id => $home->star_id }]);
is(scalar @{$result->{result}{fleet}}, 2, 'fleet sent');
# waste removed cannot be exact, due to variation in clock tick
cmp_ok($scow4->body->waste_stored, "<", 4200, 'correct waste removed');
cmp_ok($scow4->body->waste_stored, ">", 4000, 'correct waste removed');

#is($scow4->body->waste_stored, 3983, 'correct waste removed');

END {
#    TestHelper->clear_all_test_empires;
}
