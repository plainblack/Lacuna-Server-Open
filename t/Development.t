use lib '../lib';
use Test::More tests => 1;
use Test::Deep;
use Data::Dumper;
use 5.010;

use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;

my $result;

my $command = $tester->empire->home_planet->command;
$command->level(5);
$command->put;

$result = $tester->post('development', 'build', [$session_id, $tester->empire->home_planet_id, 3, 3]);

$result = $tester->post('development', 'view', [$session_id, $result->{result}{building}{id}]);

is($result->{result}{build_queue}[0]{name}, 'Development Ministry', "got build queue");

END {
    $tester->cleanup;
}
