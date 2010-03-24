use lib '../lib';
use Test::More tests => 11;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;

use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;
my $command = $home->command;

say "EMPIRE: ".$empire->id;
say "HOME PLANET: ".$home->id;

my $result;

$result = $tester->post('waterpurification', 'build', [$session_id, $home->id, 0, -5]);
ok($result->{result}{building}{id}, "built water purification");
sleep $result->{result}{building}{pending_build}{seconds_remaining} + 3;

$result = $tester->post('waterpurification', 'view', [$session_id, $result->{result}{building}{id}]);
is($result->{result}{building}{level}, 1, 'building completed without error');

$result = $tester->post('body', 'get_buildings', [$session_id, $home->id]);
say Dumper $result->{result}{buildings};

$result = $tester->post('hydrocarbon', 'build', [$session_id, $home->id, 0, -3]);
ok($result->{result}{building}{id}, "built hydrocarbon power plant");
sleep $result->{result}{building}{pending_build}{seconds_remaining} + 3;

$result = $tester->post('body', 'get_buildings', [$session_id, $home->id]);
say Dumper $result->{result}{buildings};

$result = $tester->post('mine', 'build', [$session_id, $home->id, 0, -4]);
ok($result->{result}{building}{id}, "built mine");
sleep $result->{result}{building}{pending_build}{seconds_remaining} + 3;

$result = $tester->post('body', 'get_buildings', [$session_id, $home->id]);
say Dumper $result->{result}{buildings};

$result = $tester->post('corn', 'build', [$session_id, $home->id, 0, -2]);
ok($result->{result}{building}{id}, "built corn farm");
sleep $result->{result}{building}{pending_build}{seconds_remaining} + 3;

$result = $tester->post('body', 'get_buildings', [$session_id, $home->id]);
say Dumper $result->{result}{buildings};

$result = $tester->post('university', 'build', [$session_id, $home->id, 0, -1]);
ok($result->{result}{building}{id}, "built university");
sleep $result->{result}{building}{pending_build}{seconds_remaining} + 3;

$result = $tester->post('body', 'get_buildings', [$session_id, $home->id]);
say Dumper $result->{result}{buildings};

$result = $tester->post('orestorage', 'build', [$session_id, $home->id, 0, 1]);
ok($result->{result}{building}{id}, "built ore storage tanks");
sleep $result->{result}{building}{pending_build}{seconds_remaining} + 3;

$result = $tester->post('body', 'get_buildings', [$session_id, $home->id]);
say Dumper $result->{result}{buildings};

$result = $tester->post('energyreserve', 'build', [$session_id, $home->id, 0, 2]);
ok($result->{result}{building}{id}, "built energy reserve");
sleep $result->{result}{building}{pending_build}{seconds_remaining} + 3;

$result = $tester->post('body', 'get_buildings', [$session_id, $home->id]);
say Dumper $result->{result}{buildings};

$result = $tester->post('waterproduction', 'build', [$session_id, $home->id, 0, 3]);
ok($result->{result}{building}{id}, "built water production");
sleep $result->{result}{building}{pending_build}{seconds_remaining} + 3;

$result = $tester->post('body', 'get_buildings', [$session_id, $home->id]);
say Dumper $result->{result}{buildings};

$result = $tester->post('waterstorage', 'build', [$session_id, $home->id, 0, 4]);
ok($result->{result}{building}{id}, "built water storage");
sleep $result->{result}{building}{pending_build}{seconds_remaining} + 3;

$result = $tester->post('body', 'get_buildings', [$session_id, $home->id]);
say Dumper $result->{result}{buildings};

$result = $tester->post('foodreserve', 'build', [$session_id, $home->id, 0, 5]);
ok($result->{result}{building}{id}, "built food reserve");
sleep $result->{result}{building}{pending_build}{seconds_remaining} + 3;

$result = $tester->post('body', 'get_buildings', [$session_id, $home->id]);
say Dumper $result->{result}{buildings};


END {
    $tester->cleanup;
}
