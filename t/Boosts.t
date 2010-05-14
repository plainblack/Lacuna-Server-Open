use lib '../lib';
use Test::More tests => 2;
use Test::Deep;
use Data::Dumper;
use 5.010;

use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;
$empire->add_essentia(10)->update;

my $base = $tester->post('empire','get_full_status', [$session_id]);
$tester->post('empire','boost_ore', [$session_id]);
my $boosted = $tester->post('empire','get_full_status', [$session_id]);
cmp_ok($boosted->{result}{empire}{essentia}, '<', $base->{result}{empire}{essentia}, 'essentia spent');
cmp_ok($boosted->{result}{empire}{planets}{$home->id}{ore_hour}, '>', $base->{result}{empire}{planets}{$home->id}{ore_hour}, 'ore_hour increased');


END {
    $tester->cleanup;
}
