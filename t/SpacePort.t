use lib '../lib';
use Test::More tests => 3;
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


my $uni = Lacuna::DB::Building::University->new(
    simpledb        => $tester->db,
    x               => 0,
    y               => -1,
    class           => 'Lacuna::DB::Building::University',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 2,
);
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
$home->put;


$result = $tester->post('spaceport', 'build', [$session_id, $home->id, 0, 1]);
ok($result->{result}{building}{id}, "built a space port");
my $spaceport = $empire->get_building('Lacuna::DB::Building::SpacePort',$result->{result}{building}{id});
$spaceport->finish_upgrade;

$result = $tester->post('spaceport', 'view', [$session_id, $spaceport->id]);
ok(exists $result->{result}{docked_ships}, "can see docked ships");

$result = $tester->post('spaceport', 'view_ships_travelling', [$session_id, $spaceport->id]);
is(ref $result->{result}{ships_travelling}, 'ARRAY', "can see travelling ships");

END {
    $tester->cleanup;
}
