use lib '../lib';
use Test::More tests => 15;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;

use TestHelper;
TestHelper->clear_all_test_empires;

my $tester = TestHelper->new->generate_test_empire->build_infrastructure;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;

my $result;

$result = $tester->post('embassy', 'build', [$session_id, $home->id, 0, 3]);
ok($result->{result}{building}{id}, "built an embassy");
my $embassy = $tester->get_building($result->{result}{building}{id});
$embassy->finish_upgrade;

$result = $tester->post('embassy', 'create_alliance', [$session_id, $embassy->id, 'test alliance']);
ok(exists $result->{result}, 'can create alliance');

$result = $tester->post('inbox','send_message', [$session_id, '@ally', 'my subject', "test"]);
is($result->{result}{message}{sent}[0], $tester->empire_name, 'can send allies a message');

$result = $tester->post('embassy', 'get_alliance_status', [$session_id, $embassy->id]);
ok(exists $result->{result}, 'can get alliance');

$result = $tester->post('embassy', 'update_alliance', [$session_id, $embassy->id, { forum_uri => 'http://www.google.com' }]);
ok(exists $result->{result}, 'can update alliance');

$result = $tester->post('embassy', 'send_invite', [$session_id, $embassy->id, 1]);
ok(exists $result->{result}, 'invite the lacunans');

$result = $tester->post('embassy', 'get_pending_invites', [$session_id, $embassy->id]);
ok(exists $result->{result}, 'get invitations');

$result = $tester->post('embassy', 'withdraw_invite', [$session_id, $embassy->id, $result->{result}{invites}[0]{id}]);
ok(exists $result->{result}, 'uninvite the lacunans');

$result = $tester->post('embassy', 'reject_invite', [$session_id, $embassy->id, 9999]);
is($result->{error}{code}, 1002, 'cannot reject a non-existant invite');

$result = $tester->post('embassy', 'accept_invite', [$session_id, $embassy->id, 9999]);
is($result->{error}{code}, 1002, 'cannot accept a non-existant invite');

$result = $tester->post('embassy', 'assign_alliance_leader', [$session_id, $embassy->id, 1]);
is($result->{error}{code}, 1010, 'cannot set non member as alliance leader');

$result = $tester->post('embassy', 'leave_alliance', [$session_id, $embassy->id]);
is($result->{error}{code}, 1010, 'cannot leave an alliance if you are the leader');

$result = $tester->post('embassy', 'expel_member', [$session_id, $embassy->id, 1]);
is($result->{error}{code}, 1010, 'expel member');

$result = $tester->post('embassy', 'view_stash', [$session_id, $embassy->id]);
is(ref$result->{result}{stash}, 'HASH', 'view_stash');

$result = $tester->post('embassy', 'dissolve_alliance', [$session_id, $embassy->id]);
ok(exists $result->{result}, 'dissolve alliance');

END {
    TestHelper->clear_all_test_empires;
}
