use lib '../lib';
use Test::More tests => 1;
use Test::Deep;
use Data::Dumper;
use 5.010;

use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;

my $result;

$result = $tester->post('foodreserve', 'build', [$session_id, $tester->empire->home_planet_id, 3, 3]);
my $building_id = $result->{result}{building}{id};

cmp_ok($result->{result}{food_stored}{algae}, '>', 0, "got food storage");


END {
    $tester->cleanup;
}
