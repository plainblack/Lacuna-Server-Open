use lib '../lib';
use Test::More tests => 6;
use Test::Deep;
use Data::Dumper;
use 5.010;

use TestHelper;
my $tester = TestHelper->new->generate_test_empire->build_infrastructure;
my $db = Lacuna->db;
my $empire = $tester->empire;
my $session_id = $tester->session->id;
my $home = $empire->home_planet;
my $result;

$result = $tester->post('distributioncenter', 'build', [$session_id, $home->id, 3, 3]);

my $building = $db->resultset('Lacuna::DB::Result::Building')->find($result->{result}{building}{id});
$building->finish_upgrade;

$home->water_stored(500);
$home->update;

$result = $tester->post('distributioncenter', 'reserve', [$session_id, $building->id, [
    {
        type => 'water',
        quantity    => 1000,
    },
]]);

is($result->{error}{code}, 1009, "can't reserve resources you don't have");

$result = $tester->post('distributioncenter', 'release_reserve', [$session_id, $building->id]);
is($result->{error}{code}, 1010, "can't release with nothing in reserve");

$home->water_stored(2000);
$home->update;

$result = $tester->post('distributioncenter', 'reserve', [$session_id, $building->id, [
    {
        type => 'water',
        quantity    => 1000,
    },
]]);
is($result->{result}{reserve}{resources}[0]{type}, 'water', "correct resource reserved");
is($result->{result}{reserve}{resources}[0]{quantity}, 1000, "correct amount reserved");
is($result->{result}{status}{body}{water_stored}, 1000, "resources removed from planet");

$result = $tester->post('distributioncenter', 'release_reserve', [$session_id, $building->id]);
is($result->{result}{status}{body}{water_stored}, 2000, "resources added to planet");

END {
    $tester->cleanup;
}
