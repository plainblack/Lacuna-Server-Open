use lib '../lib';
use Test::More tests => 2;
use Test::Deep;
use Data::Dumper;
use 5.010;

use TestHelper;
TestHelper->clear_all_test_empires;

my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;

my $alliances = Lacuna->db->resultset('Lacuna::DB::Result::Alliance');

my $result;

$alliances->new({
    name => 'test',
    leader_id => 1,
})->insert;

$result = $tester->post('alliance','find', [$session_id, 'test']);
is($result->{result}{alliances}[0]{name}, 'test', 'can search');

$result = $tester->post('alliance','view_profile', [$session_id, $result->{result}{alliances}[0]{id}]);
is($result->{result}{profile}{leader_id}, 1, 'can search');

END {
    $alliances->delete;
    TestHelper->clear_all_test_empires;
}
