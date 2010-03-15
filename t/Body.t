use lib '../lib';
use Test::More tests => 8;
use Test::Deep;
use Data::Dumper;
use 5.010;

use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;
my $home_planet = $tester->empire->home_planet_id;

my $result;

$result = $tester->post('body','rename', [$session_id, $home_planet, 'some rand '.rand(9999999)]);
is($result->{result}, 1, 'rename');

$result = $tester->post('body','rename', [$session_id, $home_planet, 'way too fricken long to be a valid name']);
is($result->{error}{code}, 1000, 'bad name');

$result = $tester->post('body','rename', [$session_id, 'aaa', 'new name']);
is($result->{error}{code}, 1002, 'cannot rename non-existant planet');

$result = $tester->post('body','get_buildings', [$session_id, 'aaa']);
is($result->{error}{code}, 1002, 'cannot fetch buildings on non-existant planet');

$result = $tester->post('body','get_buildings', [$session_id, $home_planet]);
is(ref $result->{result}{buildings}, 'HASH', 'fetch building list');
my $id;
foreach my $key (keys %{$result->{result}{buildings}}) {
    if ($result->{result}{buildings}{$key}{name} eq 'Planetary Command Center') {
        $id = $key;
        last;
    }
}
ok($result->{result}{buildings}{$id}{name} ne '', 'building has a name');

my $url = $result->{result}{buildings}{$id}{url};
$url =~ s/\///;
$result = $tester->post($url, 'view', [$session_id, $id]);
ok($result->{result}{building}{energy_hour} > 0, 'command center is functional');

$result = $tester->post('body', 'get_buildable', [$session_id, $home_planet, 3, 3]);
is($result->{result}{buildable}{'Wheat Farm'}{url}, '/wheat', 'Can build buildings');



END {
    $tester->cleanup;
}
