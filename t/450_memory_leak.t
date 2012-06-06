use lib '../lib';

use strict;
use warnings;

use Test::More tests => 3;
use Test::Deep;
use Test::Memory::Cycle;
use Data::Dumper;
use 5.010;
use DateTime;

use TestHelper;
my $tester = TestHelper->new->use_existing_test_empire;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;

memory_cycle_ok($home, "home has no memory cycles");

my $cache = $home->building_cache;

memory_cycle_ok($home, "no memory cycles after reading cache");

$home->tick;

memory_cycle_ok($home, "home has no memory cycles after tick");


END {
#    TestHelper->clear_all_test_empires;
}
