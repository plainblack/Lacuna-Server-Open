use lib '..','../../lib';
use Test::More tests => 2;
use Test::Deep;
use 5.010;

use strict;
use warnings;

use TestHelper;
TestHelper->clear_all_test_empires;

# BUG Plans are not displayed in alpha order in the Planetary Command Centre

my $tester = TestHelper->new({ big_producer => 1 })->generate_test_empire->build_infrastructure;
my $tester_session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;

my ($pcc) = $home->buildings_of_class('PlanetaryCommand');

$tester->post('planetarycommand', 'view_plans', [$tester_session_id, $pcc->id]);

# do something to cause a surface refresh

$tester->post('planetarycommand', 'view_plans', [$tester_session_id, $pcc->id]);


END {
#    TestHelper->clear_all_test_empires;
}
