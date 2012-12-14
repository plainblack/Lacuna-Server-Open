use lib '../lib';

use strict;
use warnings;

<<<<<<< HEAD
use Test::More tests => 7;
=======
use Test::More;
>>>>>>> 4f2b6e318cb969f21ff324ce105a8dc5b419e7aa
use Test::Deep;
use Test::Memory::Cycle;
use Data::Dumper;
use 5.010;
use DateTime;
use Lacuna;
use TestHelper;


<<<<<<< HEAD
my $now     = DateTime->now;
my $later   = DateTime->now->add( seconds => 3);

my $dur     = $later->subtract_datetime_absolute($now);
my $seconds = $dur->in_units('seconds');

is($seconds, 3, "CPAN modules agree on seconds");

my $db = Lacuna->db;
my $thing = $db->resultset('ApiKey')->create({
    public_key      => 'foo',
    private_key     => 'bar',
    name            => 'iain',
    ip_address      => '10.11.12.13',
    email           => 'iain@docherty.me',
});

my $schedule = $db->resultset('Schedule')->create({
    queue           => 'foo',
    delivery        => $later,
    parent_table    => 'ApiKey',
    parent_id       => $thing->id,
    task            => 'bar',
    args            => {this => 'siht', that => 'taht'},
});

isa_ok($schedule, 'Lacuna::DB::Result::Schedule', 'Correct class');

# Now test against beanstalk (it must be running)
#
my $queue = Lacuna::Queue->new;

isa_ok($queue, 'Lacuna::Queue', 'Correct queue class');

my $job = $queue->consume('foo');

isa_ok($job, 'Lacuna::Queue::Job', 'Correct job class');

my $payload = $job->payload;
isa_ok($payload, 'Lacuna::DB::Result::ApiKey', 'Got back an ApiKey');
is($payload->public_key,'foo', 'foo found');
is($payload->name,'iain', 'iain found');

$now = DateTime->now;
diag("later = [$later] now = [$now]");

# Delete this job, we no longer need it
$job->delete;

=======
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
>>>>>>> 4f2b6e318cb969f21ff324ce105a8dc5b419e7aa

1;

