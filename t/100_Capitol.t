use lib '../lib';
use Test::More tests => 4;
use Test::Deep;
use Data::Dumper;
use 5.010;


use TestHelper;
TestHelper->clear_all_test_empires;

my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;

my $result;

$tester->empire->add_essentia({ amount => 30, reason => 'test rename' });
$tester->empire->update;
my $capitol = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    class   => 'Lacuna::DB::Result::Building::Capitol',
    x       => 1,
    y       => 1,
});
$tester->empire->home_planet->build_building($capitol);
$capitol->finish_upgrade;


$result = $tester->post('capitol', 'view', [$session_id, $capitol->id]);
is($result->{result}{rename_empire_cost}, 29, "got rename cost");

$result = $tester->post('capitol', 'rename_empire', [$session_id, $capitol->id, 'Lacuna Expanse Corp']);
is($result->{error}{code}, 1000, "rename to an existing name errors out");


$result = $tester->post('capitol', 'rename_empire', [$session_id, $capitol->id, 'TLE Test New Name']);
is($result->{result}{status}{empire}{essentia}, 1, "essentia spent");
is($result->{result}{status}{empire}{name}, 'TLE Test New Name', "name changed");



END {
    TestHelper->clear_all_test_empires;
}
