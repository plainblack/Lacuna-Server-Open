use lib '../lib';
use Test::More tests => 3;
use Test::Deep;
use Data::Dumper;
use 5.010;


use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;



my $result;

$tester->empire->add_essentia(30, 'test rename')->update;
my $capitol = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    class   => 'Lacuna::DB::Result::Building::Capitol',
    x       => 1,
    y       => 1,
});
$tester->empire->home_planet->build_building($capitol);
$capitol->finish_upgrade;


$result = $tester->post('capitol', 'view', [$session_id, $capitol->id]);
is($result->{result}{rename_empire_cost}, 29, "got rename cost");

$result = $tester->post('capitol', 'rename_empire', [$session_id, $capitol->id, 'New Name']);
is($result->{result}{status}{empire}{essentia}, 1, "essentia spent");
is($result->{result}{status}{empire}{name}, 'New Name', "name changed");



END {
    $tester->cleanup;
}
