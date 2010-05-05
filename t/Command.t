use lib '../lib';
use Test::More tests => 2;
use Test::Deep;
use Data::Dumper;
use 5.010;


use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;

my $result;

$result = $tester->post('body','get_buildings', [$session_id, $tester->empire->home_planet_id]);

my $id;
foreach my $bid (keys %{$result->{result}{buildings}}) {
    if ($result->{result}{buildings}{$bid}{name} eq 'Planetary Command Center') {
        $id = $bid;
        last;
    }
}

$result = $tester->post('planetarycommand', 'view', [$session_id, $id]);
is($result->{result}{planet}{building_count}, 1, "got building count");

$tester->empire->home_planet->add_freebie('Lacuna::DB::Result::Building::SpacePort', 5)->put;

sleep 3;
$result = $tester->post('planetarycommand', 'view_freebies', [$session_id, $id]);
is($result->{result}{freebies}{'Space Port'}, 5, 'got freebies list');

END {
    $tester->cleanup;
}
