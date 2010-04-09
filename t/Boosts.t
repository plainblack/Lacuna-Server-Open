use lib '../lib';
use Test::More tests => 2;
use Test::Deep;
use Data::Dumper;
use 5.010;

use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;
$empire->add_essentia(10)->put;

my $base = $tester->post('empire','get_full_status', [$session_id]);
my $boost = $tester->post('empire','boost_ore', [$session_id]);
$empire = $tester->db->domain('empire')->find($empire->id);
$home->empire($empire);
my $building = Lacuna::DB::Building::Food::Farm::Malcud->new(
    simpledb        => $tester->db,
    x               => 0,
    y               => 1,
    class           => 'Lacuna::DB::Building::Food::Farm::Malcud',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 0,
);
$home->build_building($building);
$building->finish_upgrade;
my $boosts = $tester->post('empire','view_boosts', [$session_id]);
my $boosted = $tester->post('empire','get_full_status', [$session_id]);
cmp_ok($boosted->{result}{empire}{essentia}, '<', $base->{result}{empire}{essentia}, 'essentia spent');
cmp_ok($boosted->{result}{empire}{planets}{$home->id}{ore_hour} - $building->ore_hour, '>', $base->{result}{empire}{planets}{$home->id}{ore_hour}, 'ore_hour increased');


END {
    $tester->cleanup;
}
