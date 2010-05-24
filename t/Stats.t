use lib '../lib';
use Test::More tests => 8;
use Test::Deep;
use Data::Dumper;
use 5.010;

use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;


my $result = $tester->post('stats', 'credits',[]);
is($result->{result}[0]{'Game Design'}[0], 'JT Smith', 'credits');

$result = $tester->post('stats', 'overview', [$session_id]);
ok($result->{result}{stats}{stars}, "overview");

$result = $tester->post('stats', 'empires_overview', [$session_id]);
ok($result->{result}{stats}{empires}, "empire overview");

$result = $tester->post('stats', 'ships_overview', [$session_id]);
is($result->{result}{stats}{probe}{count}, 0, "ship overview");

$result = $tester->post('stats', 'buildings_overview', [$session_id]);
is($result->{result}{stats}{'Planetary Command Center'}{count}, 2, "building overview");

$result = $tester->post('stats', 'stars_overview', [$session_id]);
ok($result->{result}{stats}{stars}, "stars overview");

$result = $tester->post('stats', 'spies_overview', [$session_id]);
is($result->{result}{stats}{spies}, 0, "spies overview");

$result = $tester->post('stats', 'bodies_overview', [$session_id]);
ok($result->{result}{stats}{bodies}, "bodies overview");

END {
    $tester->cleanup;
}
