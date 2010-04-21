use lib '../lib';
use Test::More tests => 10;
use Test::Deep;
use Data::Dumper;
use 5.010;


use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;
my $home_planet = $tester->empire->home_planet_id;

my $result;


$result = $tester->post('map','get_star_by_body', [ $session_id, $home_planet]);
ok(exists $result->{result}{star}, 'get_star_by_body');
my $star_id = $result->{result}{star}{id};

$result = $tester->post('map','get_stars',[$session_id, -3,-3,2,2,0]);
is(ref $result->{result}{stars}, 'ARRAY', 'get stars');
cmp_ok(scalar(@{$result->{result}{stars}}), '>', 0, 'get stars count');
my $other_star = $result->{result}{stars}[0]{id};

$result = $tester->post('map','get_stars',[$session_id, -30,-30,30,30,0]);
is($result->{error}{code}, 1003, 'get stars too big');

$result = $tester->post('map','get_star_system', [$session_id, 'aaa']);
is($result->{error}{code}, 1002, 'get star system non-existant star');

$result = $tester->post('map','get_star_system', [$session_id, $other_star]);
is($result->{error}{code}, 1010, 'get star system no privilege');

$result = $tester->post('map','get_star_system', [$session_id, $star_id]);
is($result->{result}{star}{id},$star_id, 'get star system');

$result = $tester->post('map','check_star_for_incoming_probe', [$session_id, $star_id]);
is($result->{result}{incoming_probe}, 0, 'gcheck_star_for_incoming_probe');

$result = $tester->post('map','get_star_system_by_body', [$session_id, $home_planet]);
is($result->{result}{star}{id},$star_id, 'get star system by body');

$result = $tester->post('map','get_star_system_by_body', [$session_id, 'aaa']);
is($result->{error}{code}, 1002, 'get star system by body non-existant body');



END {
    $tester->cleanup;
}
