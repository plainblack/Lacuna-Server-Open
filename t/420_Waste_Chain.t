use lib '../lib';

use strict;
use warnings;

use Test::More tests => 25;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;

use TestHelper;
TestHelper->clear_all_test_empires;

my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;
my $command = $home->command;

my $result;

my $uni = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => -1,
    class           => 'Lacuna::DB::Result::Building::University',
    level           => 5,
});
$home->build_building($uni);
$uni->finish_upgrade;
$empire->university_level(5);
$empire->update;

my $seq = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => -2,
    class           => 'Lacuna::DB::Result::Building::Waste::Sequestration',
    level           => 29,
});
$home->build_building($seq);
$seq->finish_upgrade;

my $trade = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => -3,
    class           => 'Lacuna::DB::Result::Building::Trade',
    level           => 5,
});

$home->build_building($trade);
$trade->finish_upgrade;

$home->ore_hour(5000);
$home->water_hour(5000);
$home->energy_hour(5000);
$home->algae_production_hour(5000);
$home->ore_capacity(5000);
$home->energy_capacity(5000);
$home->food_capacity(5000);
$home->water_capacity(5000);
$home->waste_capacity(8000);
$home->bauxite_stored(5000);
$home->algae_stored(5000);
$home->energy_stored(5000);
$home->water_stored(5000);
$home->waste_stored(10000000);
$home->needs_recalc(0);
$home->tick;
$home->update;

cmp_ok($home->waste_stored, "=", 100000, 'correct original waste');

$empire->is_isolationist(0);
$empire->update;

$result = $tester->post('spaceport', 'build', [$session_id, $home->id, 0, 1]);
my $spaceport = $tester->get_building($result->{result}{building}{id});
$spaceport->finish_upgrade;

my $shipyard = Lacuna::db->resultset('Lacuna::DB::Result::Building')->new({
	x       => 0,
	y       => 2,
	class   => 'Lacuna::DB::Result::Building::Shipyard',
	level   => 20,
});
$home->build_building($shipyard);
$shipyard->finish_upgrade;

$home->discard_changes;
$home->waste_stored(1000000);
$home->update;

my $scow = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'scow'});
$shipyard->build_ship($scow);
my $scow_large = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'scow_large'});
$shipyard->build_ship($scow_large);

my $finish = DateTime->now;

Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({shipyard_id=>$shipyard->id})->update({date_available=>$finish});

$result = $tester->post('spaceport', 'view', [$session_id, $spaceport->id]);

Lacuna->cache->set('captcha', $session_id, { guid => 1111, solution => 1111 }, 60 * 30 );

$result = $tester->post('spaceport', 'send_ship', [$session_id, $scow->id, { star_id => $home->star_id } ] );
ok($result->{result}{ship}{date_arrives}, "scow sent to star id " . $home->star_id);
$scow->discard_changes;

is( $scow->foreign_star_id, $home->star_id, 'scow is headed to the correct foreign star id' );
is( $scow->foreign_body_id, undef, 'scow does not have a foreign body id' );
#diag(Dumper($scow->payload));

$scow->arrive;
is( $scow->task, 'Travelling', 'scow is travelling' );
is( $scow->direction, 'in', 'scow is headed home' );

$scow->discard_changes;
$scow->arrive;
is( $scow->task, 'Docked', 'scow is docked' );
cmp_deeply( $scow->payload, {}, 'no payload' );

$result = $tester->post('captcha','solve', [$session_id, 1111, 1111]);
is($result->{result}, 1, 'Solved captcha');

$home->discard_changes;
cmp_ok($home->waste_stored, "<", 950_000, 'correct waste removed');
cmp_ok($home->waste_stored, ">", 940_000, 'correct waste removed');

#diag("Waste per hour [".$home->waste_hour."]");
my $old_waste_per_hour = $home->waste_hour;

$result = $tester->post('trade','get_waste_ships', [$session_id, $trade->id]);
#diag(Dumper($result->{result}{ships}));
my @temp = map { {task => $_->{task}, type => $_->{type} } } @{$result->{result}{ships}};
my @comp = ({type=>'scow',task=>'Docked'},{type=>'scow_large',task=>'Docked'});
cmp_deeply(\@comp,\@temp, "All ships docked");

my $original_waste_hour = $result->{result}{status}{body}{waste_hour};
#diag(Dumper($result->{result}));
#diag("original waste per hour [$original_waste_hour]");
is($old_waste_per_hour, $original_waste_hour, "Compare waste hour");
my @ship_types = sort map {$_->{type}} @{$result->{result}{ships}};
#diag(Dumper(\@ship_types));
cmp_deeply(\@ship_types, [qw(scow scow_large)], "scow ship types");
# set up a waste chain with the scow

$result = $tester->post('trade','view_waste_chains', [$session_id, $trade->id]);
my $waste_chain = $result->{result}{waste_chain}[0];
#diag(Dumper($waste_chain));
is($waste_chain->{waste_hour}, 0, "Waste chain is empty");
is($waste_chain->{percent_transferred}, 0, "Zero percent");
my $waste_chain_id = $waste_chain->{id};
$result = $tester->post('trade','add_waste_ship_to_fleet',[$session_id, $trade->id, $scow->id]);
my $new_waste_per_hour = $result->{result}{status}{body}{waste_hour};
is($old_waste_per_hour, $new_waste_per_hour, "Waste per hour has not yet changed");

# add waste to the chain
$result = $tester->post('trade','update_waste_chain', [$session_id, $trade->id, $waste_chain_id, 1000]);
$new_waste_per_hour = $result->{result}{status}{body}{waste_hour};
#diag("Old waste hour [$old_waste_per_hour], New waste hour [$new_waste_per_hour]");
is($old_waste_per_hour - $new_waste_per_hour, 1000, "Correct amount of waste deducted");

$result = $tester->post('trade','view_waste_chains', [$session_id, $trade->id]);
$waste_chain = $result->{result}{waste_chain}[0];
cmp_ok($waste_chain->{percent_transferred}, "<", 7300, "Too much shipping capacity");
cmp_ok($waste_chain->{percent_transferred}, ">", 7200, "Too much shipping capacity");

# try to add a scow large (without the requisite berth level)
$result = $tester->post('trade','add_waste_ship_to_fleet',[$session_id, $trade->id, $scow_large->id]);
is($result->{error}{code}, 1009, "Scow large not allowed with berth level");

# Increase Space Port level and try again
$spaceport = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 1,
    y               => -1,
    class           => 'Lacuna::DB::Result::Building::SpacePort',
    level           => 15,
});

$home->build_building($spaceport);
$spaceport->finish_upgrade;

$result = $tester->post('trade','add_waste_ship_to_fleet',[$session_id, $trade->id, $scow_large->id]);
$new_waste_per_hour = $result->{result}{status}{body}{waste_hour};
#diag("New-new waste per hour [$new_waste_per_hour]");

$result = $tester->post('trade','get_waste_ships', [$session_id, $trade->id]);
@temp = map { {task => $_->{task}, type => $_->{type} } } @{$result->{result}{ships}};
@comp = ({type=>'scow',task=>'Waste Chain'},{type=>'scow_large',task=>'Waste Chain'});
cmp_deeply(\@comp,\@temp, "All ships in waste chain");

# transport enough waste to get to zero per hour
my $total_waste_per_hour = 1000 + $new_waste_per_hour;

$result = $tester->post('trade','update_waste_chain', [$session_id, $trade->id, $waste_chain_id, $total_waste_per_hour]);
$new_waste_per_hour = $result->{result}{status}{body}{waste_hour};
#diag("New-new waste per hour [$new_waste_per_hour]");
is($new_waste_per_hour, 0, "Waste set to zero");

# remove one of the ships
$result = $tester->post('trade','remove_waste_ship_from_fleet', [$session_id, $trade->id, $scow->id]);
$new_waste_per_hour = $result->{result}{status}{body}{waste_hour};
#diag("New-new waste per hour [$new_waste_per_hour]");
is($new_waste_per_hour, 0, "Waste still at zero after ship removed");

# remove all ships
$result = $tester->post('trade','remove_waste_ship_from_fleet', [$session_id, $trade->id, $scow_large->id]);
my $final_waste_per_hour = $result->{result}{status}{body}{waste_hour};
#diag("Final waste per hour [$final_waste_per_hour]");
is($final_waste_per_hour, $total_waste_per_hour, "Waste back to normal");

END {
#    TestHelper->clear_all_test_empires;
}
