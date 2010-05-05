use lib '../lib';
use Test::More tests => 2;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;

use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;


my $result;


my $uni = Lacuna::DB::Result::Building::University->new(
    simpledb        => $tester->db,
    x               => 0,
    y               => -1,
    class           => 'Lacuna::DB::Result::Building::University',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 2,
);
$home->build_building($uni);
$uni->finish_upgrade;

my $intelligence = Lacuna::DB::Result::Building::Intelligence->new(
    simpledb        => $tester->db,
    x               => 0,
    y               => -2,
    class           => 'Lacuna::DB::Result::Building::Intelligence',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 1,
);
$home->build_building($intelligence);
$intelligence->finish_upgrade;

$home->ore_capacity(5000);
$home->energy_capacity(5000);
$home->food_capacity(5000);
$home->water_capacity(5000);
$home->bauxite_stored(5000);
$home->algae_stored(5000);
$home->energy_stored(5000);
$home->water_stored(5000);
$home->ore_hour(5000);
$home->energy_hour(5000);
$home->algae_production_hour(5000);
$home->water_hour(5000);
$home->needs_recalc(0);
$home->put;


$result = $tester->post('security', 'build', [$session_id, $home->id, 0, 1]);
ok($result->{result}{building}{id}, "built a security ministry");
my $security = $empire->get_building('Lacuna::DB::Result::Building::Security',$result->{result}{building}{id});
$security->finish_upgrade;

$result = $tester->post('security', 'view_prisoners', [$session_id, $security->id]);
is(ref $result->{result}{prisoners}, 'ARRAY', "view prisoners");


END {
    $tester->cleanup;
}
