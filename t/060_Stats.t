use lib '../lib';
use Test::More tests => 8;
use Test::Deep;
use Data::Dumper;
use 5.010;

use TestHelper;
TestHelper->clear_all_test_empires;

my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;


my $result = $tester->post('stats', 'credits',[]);
is($result->{result}[0]{'Game Design'}[0], 'JT Smith', 'credits');

$result = $tester->post('stats', 'weekly_medal_winners', [$session_id]);
ok(exists $result->{result}, "weekly medal winners");

$result = $tester->post('stats', 'spy_rank', [$session_id]);
ok(exists $result->{result}, "spy_rank");

$result = $tester->post('stats', 'colony_rank', [$session_id]);
ok(exists $result->{result}, "colony_rank");

$result = $tester->post('stats', 'empire_rank', [$session_id]);
ok(exists $result->{result}, "empire_rank");

$result = $tester->post('stats', 'find_empire_rank', [$session_id, 'empire_size_rank', 'test']);
ok(exists $result->{result}, "find_empire_rank");

$result = $tester->post('stats', 'alliance_rank', [$session_id]);
ok(exists $result->{result}, "alliance_rank");

$result = $tester->post('stats', 'find_alliance_rank', [$session_id, 'average_empire_size_rank', 'test']);
ok(exists $result->{result}, "find_alliance_rank");

END {
    TestHelper->clear_all_test_empires;
}
