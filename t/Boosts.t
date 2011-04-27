use lib '../lib';
use Test::More tests => 6;
use Test::Deep;
use Data::Dumper;
use 5.010;
use Lacuna::Util qw(format_date);

use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;
$empire->add_essentia(10,'testing boosts')->update;

my $base = $tester->post('body','get_status', [$session_id, $home->id]);
$tester->post('empire','boost_ore', [$session_id]);
my $boosted = $tester->post('body','get_status', [$session_id, $home->id]);
cmp_ok($boosted->{result}{empire}{essentia}, '<', $base->{result}{empire}{essentia}, 'essentia spent');
cmp_ok($boosted->{result}{body}{ore_hour}, '>', $base->{result}{body}{ore_hour}, 'ore_hour increased');
$empire->discard_changes;
$empire->ore_boost(DateTime->now->subtract(seconds=>60));
$empire->update;
$empire->add_essentia(25,'testing boosts')->update;
my $unboosted = $tester->post('body','get_status', [$session_id, $home->id]);
$empire->update;
cmp_ok($boosted->{result}{body}{ore_hour}, '>', $unboosted->{result}{body}{ore_hour}, 'ore_hour decreased');
my $unboost_message_recieved = $empire->received_messages->search({ subject => { -like => 'Boosts Have Expired%' } })->count;
ok($unboost_message_recieved, 'unboost message received');
$tester->post('empire','boost_rpc', [$session_id]);
my $check = $tester->post('empire','get_status', [$session_id, $empire->id]);
my $limit = $check->{result}{server}{rpc_limit};
Lacuna->cache->set('rpc_count_'.format_date(undef,'%d'), $empire->id, $limit, 60 * 60 * 26);
$check = $tester->post('empire','get_status', [$session_id, $home->id]);
my $limit1 = $limit+1;
is($check->{result}{empire}{rpc_count}, $limit1, "rpc_count is $limit1, no error");
$limit *= 2;
Lacuna->cache->set('rpc_count_'.format_date(undef,'%d'), $empire->id, $limit, 60 * 60 * 26);
$check = $tester->post('empire','get_status', [$session_id, $home->id]);
is($check->{error}{code}, 1010, 'Reached my boosted limit');
END {
    $tester->cleanup;
}
