use lib '../lib';

use strict;
use warnings;

use Test::More tests => 13;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;

use TestHelper;
my $tester = TestHelper->new->use_existing_test_empire;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;
my $command = $home->planetary_command;

my $result;

my $space_port = Lacuna->db->resultset('Building')->search({
    class => 'Lacuna::DB::Result::Building::SpacePort',
    body_id => $home->id,
    },{
    rows => 1,
})->single;
goto FLEET;

$result = $tester->post('spaceport','get_fleet_for', [$session_id, $home->id, {body_name => 'DeLambert-5-28'}]);

my ($sweepers) = grep {$_->{type} eq 'sweeper'} @{$result->{result}{ships}};

diag Dumper(\$sweepers);

Lacuna->cache->set('captcha', $session_id, { guid => 1111, solution => 1111 }, 60 * 30 );
$result = $tester->post('captcha','solve', [$session_id, 1111, 1111]);
is($result->{result}, 1, 'Solved captcha');

$result = $tester->post('spaceport','send_ship_types', [
    $session_id,
    $home->id,
    {body_name => 'DeLambert-5-28'},
    [{type => 'sweeper', speed => $sweepers->{speed}, stealth => $sweepers->{stealth}, combat => $sweepers->{combat}, quantity => 10}],
    {day => 10, hour => 0, minute => 0, second => 0},
]);
FLEET:
# check fleets
my $now = DateTime->now;
my $attributes = {
    shipyard_id         => 0,
    date_started        => "2012-01-01 01:02:03",
    date_available      => "2012-01-01 01:02:03",
    mark                => '',
    type                => 'galleon',
    task                => 'Docked',
    name                => 'Galleon 1',
    speed               => 5000,
    stealth             => 0,
    combat              => 0,
    hold_size           => 800000,
    payload             => '{"spies":["5344","5346","5352","5360"]}',
    roundtrip           => 0,
    direction           => 'in',
    berth_level         => 0,
    quantity            => 100,
};
# Clear out any existing fleet
my $fleet = $home->add_to_fleets($attributes);
$home->fleets->search({mark => $fleet->mark})->delete_all;
# make a test fleet
my $fleet_1 = $home->add_to_fleets($attributes);
ok(defined $fleet_1, "Fleet object is defined");
is($fleet_1->quantity, 100, "Correct quantity");
my $original_mark = $fleet_1->mark;
$fleet_1->delete_quantity(9);
is($original_mark, $fleet_1->mark, "Mark not changed by quantity");
is($fleet_1->quantity, 91, "Deleted the correct number of ships");

# make a second test fleet
my $fleet_2 = $home->add_to_fleets($attributes);
is($fleet_1->mark, $fleet_2->mark, "Identical fleets have identical marks");
my $no_fleets = $home->fleets->search({mark => $fleet->mark})->count;
is($no_fleets, 2, "Should have two fleets");

# update one, which should merge them
$fleet_2->delete_quantity(1);
is($fleet_2->quantity, 190, "Should have merged the fleets");

# now split out some into another fleet
my $fleet_3 = $fleet_2->split(3);
is($fleet_3->quantity, 3, "Split fleet should have 3 ships");
is($fleet_2->quantity, 187, "Original fleet should be depleted");
is($fleet_3->mark, $fleet->mark, "Split fleet has correct mark");
is($fleet_2->mark, $fleet->mark, "Original fleet has correct mark");

# now make some changes to the new fleet
$fleet_3->payload('{}');
$fleet_3->update;
isnt($fleet_3->mark, $fleet->mark, "Split fleet has different mark");

# make a change that should merge the fleet
$fleet_3->payload($fleet_2->payload);
$fleet_3->update;
is($fleet_3->quantity, 190, "Fleets are merged again");

#my $new_fleet = $fleet





END {
#    TestHelper->clear_all_test_empires;
}
