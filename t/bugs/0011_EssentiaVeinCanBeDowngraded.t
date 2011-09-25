use lib '..','../../lib';
use Test::More tests => 2;
use Test::Deep;
use 5.010;

use strict;
use warnings;

use TestHelper;
TestHelper->clear_all_test_empires;

# BUG Essentia vein can be downgraded

my $tester = TestHelper->new({ big_producer => 1 })->generate_test_empire->build_infrastructure;
my $tester_session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;

my $essentia_vein = $tester->build_building('Lacuna::DB::Result::Building::Permanent::EssentiaVein', 2);


END {
#    TestHelper->clear_all_test_empires;
}
