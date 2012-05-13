use lib '../lib';

use strict;
use warnings;

use Test::More tests => 10;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;

use TestHelper;
my $tester = TestHelper->new->use_existing_test_empire;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;
my $command = $home->command;

my $result;

my $space_port = Lacuna->db->resultset('Building')->search({
    class => 'Lacuna::DB::Result::Building::SpacePort',
    body_id => $home->id,
    },{
    rows => 1,
})->single;

$result = $tester->post('spaceport','get_fleet_for', [$session_id, $home->id, {body_name => 'DeLambert-5-28'}]);

END {
#    TestHelper->clear_all_test_empires;
}
