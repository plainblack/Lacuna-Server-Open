use lib '..','../../lib';
use Test::More tests => 2;
use Test::Deep;
use 5.010;

use strict;
use warnings;

use TestHelper;
TestHelper->clear_all_test_empires;

# BUG Bleeders continue to upgrade above level 30

my $tester = TestHelper->new({ big_producer => 1 })->generate_test_empire->build_infrastructure;
my $tester_session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;

my $deployed_bleeder = $tester->build_building('Lacuna::DB::Result::Building::DeployedBleeder', 29);

$deployed_bleeder->start_upgrade;
$deployed_bleeder->finish_upgrade;

is($deployed_bleeder->level, 30, 'Deployed bleeder should be at level 30');
is($deployed_bleeder->is_upgrading, 0, 'Deployed bleeder should not be upgrading');

END {
#    TestHelper->clear_all_test_empires;
}
