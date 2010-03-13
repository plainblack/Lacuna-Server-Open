use lib '../lib';
use Test::More tests => 1;
use Test::Deep;
use Data::Dumper;
use 5.010;


use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $db = $tester->db;
my $empire = $tester->empire;
my $session_id = $tester->session->id;

my $result;

$result = $tester->post('orestorage', 'build', [$session_id, $empire->home_planet_id, 3, 3]);
my $building_id = $result->{result}{building}{id};

cmp_ok($result->{result}{ore_stored}{bauxite}, '>', 0, "got ore storage");

END {
    $tester->cleanup;
}
