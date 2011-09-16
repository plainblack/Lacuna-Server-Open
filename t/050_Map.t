use lib '../lib';
use Test::More tests => 5;
use Test::Deep;
use Data::Dumper;
use 5.010;


use TestHelper;
TestHelper->clear_all_test_empires;

my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;
my $home_planet = $tester->empire->home_planet;

my $result;


my $star_id = $home_planet->star_id;

$result = $tester->post('map','get_stars',[$session_id, -3,-3,2,2]);
is(ref $result->{result}{stars}, 'ARRAY', 'get stars');
cmp_ok(scalar(@{$result->{result}{stars}}), '>', 0, 'get stars count');
my $other_star = $result->{result}{stars}[0]{id};

$result = $tester->post('map','get_stars',[$session_id, -30,-30,30,30]);
is($result->{error}{code}, 1003, 'get stars too big');

$result = $tester->post('map','get_star', [$session_id, $star_id]);
is($result->{result}{star}{id},$star_id, 'get star system');

$result = $tester->post('map','check_star_for_incoming_probe', [$session_id, $star_id]);
is($result->{result}{incoming_probe}, 0, 'gcheck_star_for_incoming_probe');


END {
    TestHelper->clear_all_test_empires;
}
