use lib '../lib';
use Test::More tests => 7;
use Test::Deep;
use Data::Dumper;
use 5.010;

use TestHelper;
TestHelper->clear_all_test_empires;

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
        quantity    => 10000,
    },
]]);

is($result->{error}{code}, 1009, "can't reserve resources you don't have");

$result = $tester->post('distributioncenter', 'release_reserve', [$session_id, $building->id]);
is($result->{error}{code}, 1010, "can't release with nothing in reserve");

$home->water_stored(20000);
$home->update;

$result = $tester->post('distributioncenter', 'reserve', [$session_id, $building->id, [
    {
        type => 'water',
        quantity    => 10000,
    },
]]);
is($result->{result}{reserve}{resources}[0]{type}, 'water', "correct resource reserved");
is($result->{result}{reserve}{resources}[0]{quantity}, 10000, "correct amount reserved");
# Because the PCC is running, producing resources while the test is running, then the numbers are slightly out
# expect a small positive excess (caused by production in the mean time)
cmp_ok($result->{result}{status}{body}{water_stored}, '<', 10500, "resources removed from planet");

$result = $tester->post('distributioncenter', 'release_reserve', [$session_id, $building->id]);
my $resources_stored = $result->{result}{status}{body}{water_stored};
cmp_ok($resources_stored, '>', 20000, "resources added to planet");
cmp_ok($resources_stored, '<', 20500, "not too many resources added to planet");

END {
    TestHelper->clear_all_test_empires;
}
