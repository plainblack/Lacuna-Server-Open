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

my $gratchs_gauntlet = $tester->build_building('Lacuna::DB::Result::Building::Permanent::GratchsGauntlet', 2);

$home->add_plan('Lacuna::DB::Result::Building::Permanent::GratchsGauntlet', 1);
$home->add_plan('Lacuna::DB::Result::Building::Permanent::GratchsGauntlet', 2);

$home->add_plan('Lacuna::DB::Result::Building::Permanent::GratchsGauntlet', 3);
$home->add_plan('Lacuna::DB::Result::Building::Permanent::GratchsGauntlet', 4);

END {
#    TestHelper->clear_all_test_empires;
}
