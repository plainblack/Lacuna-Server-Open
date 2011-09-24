use lib '..','../../lib';
use Test::More tests => 2;
use Test::Deep;
use 5.010;

use strict;
use warnings;

use TestHelper;
TestHelper->clear_all_test_empires;

# BUG High Negative happiness and very long build times cause exceptions

my $tester = TestHelper->new({ big_producer => 1 })->generate_test_empire->build_infrastructure;
my $tester_session_id = $tester->session->id;
my $empire = $tester->empire;

$empire->is_isolationist(0);
$empire->update;
my $home = $empire->home_planet;

$tester->build_building('Lacuna::DB::Result::Building::Permanent::PyramidJunkSculpture',   25);
# build halls
for (0 .. 30) {
    $tester->build_building('Lacuna::DB::Result::Building::Permanent::HallsOfVrbansk', 1);
}


$home->happiness(-1000,000,000,000,000);
$home->update;
$home->tick;




END {
#    TestHelper->clear_all_test_empires;
}
