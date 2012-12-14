use lib '../lib';

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Memory::Cycle;
use Data::Dumper;
use 5.010;
use DateTime;
use Lacuna;
use TestHelper;


my $tester      = TestHelper->new->use_existing_test_empire;
my $session_id  = $tester->session->id;
my $empire      = $tester->empire;
my $home        = $empire->home_planet;

# Demolish all 'algae' test buildings
#
my $algae_rs = Lacuna->db->resultset('Building')->search({
    class           => 'Lacuna::DB::Result::Building::Food::Algae',
    body_id         => $home->id,
});
while (my $algae_building = $algae_rs->next) {
    diag("Demolishing algae ".$algae_building->id);
    $algae_building->demolish;
};


# Test construction of a level 1 building
#
$tester->find_empty_plot;
my $building_1 = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => $tester->x,
    y               => $tester->y,
    class           => 'Lacuna::DB::Result::Building::Food::Algae',
    level           => 0,
});
$home->build_building($building_1);
diag("Building ".$building_1->id." ends at ".$building_1->upgrade_ends);

sleep 3;

$tester->find_empty_plot;
my $building_2 = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => $tester->x,
    y               => $tester->y,
    class           => 'Lacuna::DB::Result::Building::Food::Algae',
    level           => 0,
});
$home->build_building($building_2);
diag("Building ".$building_2->id." ends at ".$building_2->upgrade_ends);


my $retry = 0;
my $building_1_complete;
my $building_2_complete;
TICK:
while () {
    sleep 1;
    $building_1->discard_changes;
    $building_2->discard_changes;
    diag("tick: ".++$retry);

    if (not $building_1_complete and not $building_1->is_upgrading) {
        cmp_ok($retry, '>=', 12, "upgrade is not premature");
        cmp_ok($retry, '<', 15, "upgrade is not late");
        $building_1_complete = 1;
    }
    if (not $building_2_complete and not $building_2->is_upgrading) {
        cmp_ok($retry, '>=', 27, "upgrade is not premature");
        cmp_ok($retry, '<', 30, "upgrade is not late");
        $building_2_complete = 1;
    }
    last TICK if $building_1_complete and $building_2_complete;

    if ($retry > 32) {
        fail("Build did not terminate in time");
        last TICK;
    }

}

sleep 1;

done_testing;

1;

