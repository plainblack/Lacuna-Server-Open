use lib '../lib';
use Test::More tests => 1;
use Test::Deep;
use Data::Dumper;
use 5.010;


use TestHelper;
TestHelper->clear_all_test_empires;

my $tester = TestHelper->new->generate_test_empire;

my $db = Lacuna->db;
my $empire = $tester->empire;
my $session_id = $tester->session->id;

my $result;

$result = $tester->post('orestorage', 'build', [$session_id, $empire->home_planet_id, 3, 3]);
my $building_id = $result->{result}{building}{id};

$result = $tester->post('orestorage', 'view', [$session_id, $building_id]);
ok(exists $result->{result}{ore_stored}{bauxite}, "got ore storage");

END {
    TestHelper->clear_all_test_empires;
}
