use lib '../lib';
use Test::More tests => 9;
use Test::Deep;
use Data::Dumper;
use 5.010;


use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;

my $result;

my $last_energy = $tester->empire->home_planet->energy_stored;
my $empire_id = $tester->empire->id;
my $home_planet = $tester->empire->home_planet_id;
my $db = $tester->db;

$result = $tester->post('wheat', 'build', [$session_id, $home_planet, 3, 3]);
is($result->{result}{building}{name}, 'Wheat Farm', 'Can build buildings');
is($result->{result}{building}{level}, 0, 'New building is level 0');
cmp_ok($result->{result}{building}{pending_build}{seconds_remaining}, '>', 0, 'Building has time in queue');
cmp_ok($last_energy, '>', $result->{result}{status}{empire}{planets}{$home_planet}{energy_stored}, 'Resources are being spent.');

my $building = $db->domain('food')->find($result->{result}{building}{id});
$building->finish_upgrade;

$result = $tester->post('wheat', 'view', [$session_id, $building->id]);
is($result->{result}{building}{level}, 1, 'New building is built');
ok(! exists $result->{result}{building}{pending_build}, 'Building is no longer in build queue');
$last_energy = $result->{result}{status}{empire}{planets}{$home_planet}{energy_stored};

my $empire = $db->domain('empire')->find($empire_id);
$empire->university_level(5);
$empire->put;

$result = $tester->post('wheat', 'upgrade', [$session_id, $building->id]);
is($result->{result}{building}{level}, 1, 'Upgrading building is still level 1');
cmp_ok($result->{result}{building}{pending_build}{seconds_remaining}, '>', 0, 'Upgrade has time in queue');
cmp_ok($last_energy, '>', $result->{result}{status}{empire}{planets}{$home_planet}{energy_stored}, 'Resources are being spent for upgrade.');


END {
    $tester->cleanup;
}
