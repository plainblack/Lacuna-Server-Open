use lib '../lib';
use Test::More tests => 4;
use Test::Deep;
use Data::Dumper;
use 5.010;

use TestHelper;
TestHelper->clear_all_test_empires;

my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;
$empire->add_essentia({ amount => 10, reason => 'testing boosts'});
$empire->update;

my $base = $tester->post('body','get_status', [$session_id, $home->id]);
$tester->post('empire','boost_ore', [$session_id]);
my $boosted = $tester->post('body','get_status', [$session_id, $home->id]);
cmp_ok($boosted->{result}{empire}{essentia}, '<', $base->{result}{empire}{essentia}, 'essentia spent');
cmp_ok($boosted->{result}{body}{ore_hour}, '>', $base->{result}{body}{ore_hour}, 'ore_hour increased');
$empire->discard_changes;
$empire->ore_boost(DateTime->now->subtract(seconds=>60));
$empire->update;
my $unboosted = $tester->post('body','get_status', [$session_id, $home->id]);
$empire->update;
cmp_ok($boosted->{result}{body}{ore_hour}, '>', $unboosted->{result}{body}{ore_hour}, 'ore_hour decreased');
my $unboost_message_recieved = $empire->received_messages->search({ subject => { -like => 'Boosts Have Expired%' } })->count;
ok($unboost_message_recieved, 'unboost message received');

END {
    TestHelper->clear_all_test_empires;
}
