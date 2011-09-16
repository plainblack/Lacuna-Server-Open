use lib '../lib';
use Test::More tests => 2;
use Test::Deep;
use Data::Dumper;
use 5.010;

use TestHelper;
TestHelper->clear_all_test_empires;

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

$tester->empire->home_planet->add_plan('Lacuna::DB::Result::Building::SpacePort', 5);

$result = $tester->post('planetarycommand', 'view_plans', [$session_id, $id]);
is($result->{result}{plans}[0]{name}, 'Space Port', 'got plans list');

END {
    TestHelper->clear_all_test_empires;
}
