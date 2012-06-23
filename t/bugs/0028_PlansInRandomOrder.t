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

# add an assortment of plans of different names and levels

$home->add_plan('Lacuna::DB::Result::Building::Permanent::Ravine', 1);
$home->add_plan('Lacuna::DB::Result::Building::Permanent::Ravine', 1, 2);
$home->add_plan('Lacuna::DB::Result::Building::Permanent::Ravine', 4);
$home->add_plan('Lacuna::DB::Result::Building::Permanent::Ravine', 1);
$home->add_plan('Lacuna::DB::Result::Building::Permanent::Ravine', 3);
$home->add_plan('Lacuna::DB::Result::Building::Permanent::Ravine', 1,1);
$home->add_plan('Lacuna::DB::Result::Building::Permanent::Lake', 1);
$home->add_plan('Lacuna::DB::Result::Building::Permanent::AlgaePond', 1);

my ($pcc) = $home->buildings_of_class('PlanetaryCommand');

$tester->post('planetarycommand', 'view_plans', [$session_id, $shipyard->id, 'dory']);

diag($pcc->id);

END {
#    TestHelper->clear_all_test_empires;
}
