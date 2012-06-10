use lib '../lib';

use strict;
use warnings;

use Test::More;
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

$result = $tester->post('spaceport','view', [$session_id, $space_port->id]);

my $sweepers = $result->{result}{docked_ships}{sweeper};
diag("Sweepers = [$sweepers]");

my $fleets = $home->fleets->search({
    task => 'Docked',
});
my $ships;
while (my $fleet = $fleets->next) {
    $ships->{$fleet->type} += $fleet->quantity;
}
foreach my $ship (sort keys %{$result->{result}{docked_ships}} ) {
    is($result->{result}{docked_ships}{$ship}, $ships->{$ship}, "Correct number of docked $ship");
}

$result = $tester->post('spaceport','view_all_fleets', [$session_id, $space_port->id, {no_paging => 1}]);
$fleets = $home->fleets->search;
while (my $fleet = $fleets->next) {
    my ($result_fleet) = grep {$_->{id} == $fleet->id} @{$result->{result}{fleets}};
    ok($result_fleet, "Fleet (".$result_fleet->{type}.")is in the results");
    is($result_fleet->{task},     $fleet->task, "Tasks are the same");
    is($result_fleet->{quantity}, $fleet->quantity, "Quantities are the same");
}


done_testing;

END {
#    TestHelper->clear_all_test_empires;
}
