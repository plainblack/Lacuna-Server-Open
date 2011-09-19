use lib '../lib';
use Test::More tests => 14;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;

use TestHelper;
TestHelper->clear_all_test_empires;

my $tester = TestHelper->new->generate_test_empire->build_infrastructure;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;
my $command = $home->command;

my $result;

$result = $tester->post('spaceport', 'build', [$session_id, $home->id, 0, 1]);
my $spaceport = $tester->get_building($result->{result}{building}{id});
$spaceport->finish_upgrade;

$result = $tester->post('shipyard', 'build', [$session_id, $home->id, 0, 2]);
ok($result->{result}{building}{id}, "built a shipyard");
my $shipyard = $tester->get_building($result->{result}{building}{id});
$shipyard->finish_upgrade;

my $probe = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'probe'});

my $shipyard2 = $tester->get_building($shipyard->id);
my @resources = qw(food water energy time waste ore);
foreach my $resource (@resources) {
    is($shipyard->get_ship_costs($probe)->{$resource}, $shipyard2->get_ship_costs($probe)->{$resource}, "shipyard calculates $resource cost the same twice");
}

$result = $tester->post('shipyard', 'get_buildable', [$session_id, $shipyard->id]);
is($result->{result}{buildable}{probe}{can}, 0, "ships not buildable yet");
my $probe_cost = $result->{result}{buildable}{probe}{cost};

$result = $tester->post('shipyard', 'get_buildable', [$session_id, $shipyard->id]);
foreach my $resource (@resources) {
    is($probe_cost->{$resource}, $result->{result}{buildable}{probe}{cost}{$resource}, "$resource cost matches on two displays");
}

END {
    TestHelper->clear_all_test_empires;
}
