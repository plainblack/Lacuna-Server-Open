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
    })->first;

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

END {
#    TestHelper->clear_all_test_empires;
}
