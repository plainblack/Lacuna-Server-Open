use lib '../lib';
use Test::More tests => 1;
use Test::Deep;
use Data::Dumper;
use 5.010;

use TestHelper;
TestHelper->clear_all_test_empires;

my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;
my $db = Lacuna->db;

my $result;

my $pcc = $home->command;

$result = $tester->post('planetarycommand', 'view_plans', [$session_id, $pcc->id]);

is(ref $result->{result}{plans}, 'ARRAY', 'can view plans');


END {
    TestHelper->clear_all_test_empires;
}
