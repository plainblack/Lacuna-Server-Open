use lib '../lib';
use Test::More tests => 3;
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

my $result;

my $uni = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => -1,
    class           => 'Lacuna::DB::Result::Building::University',
    level           => 2,
});
$home->build_building($uni);
$uni->finish_upgrade;

my $intelligence = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
    x               => 0,
    y               => -2,
    class           => 'Lacuna::DB::Result::Building::Intelligence',
    level           => 1,
});
$home->build_building($intelligence);
$intelligence->finish_upgrade;

$home->ore_capacity(5000);
$home->energy_capacity(5000);
$home->food_capacity(5000);
$home->water_capacity(5000);
$home->bauxite_stored(5000);
$home->algae_stored(5000);
$home->energy_stored(5000);
$home->water_stored(5000);
$home->ore_hour(5000);
$home->energy_hour(5000);
$home->algae_production_hour(5000);
$home->water_hour(5000);
$home->needs_recalc(0);
$home->update;


$result = $tester->post('security', 'build', [$session_id, $home->id, 0, 1]);
ok($result->{result}{building}{id}, "built a security ministry");
my $security = $tester->get_building($result->{result}{building}{id});
$security->finish_upgrade;

my $lacunans = $empire->lacuna_expanse_corp;
my $spy = Lacuna->db->resultset('Spies')->new({
    empire_id       => $lacunans->id,
    from_body_id    => $lacunans->home_planet_id,
    on_body_id      => $home->id,
    available_on    => DateTime->now->add(minutes => 10),
    level           => 1,
})->insert;

$result = $tester->post('security', 'view_foreign_spies', [$session_id, $security->id]);
is(scalar(@{$result->{result}{spies}}), 1, "view foreign spies");

$spy->task('Captured');
$spy->update;

$result = $tester->post('security', 'view_prisoners', [$session_id, $security->id]);
is(scalar(@{$result->{result}{prisoners}}), 1, "view prisoners");


END {
    TestHelper->clear_all_test_empires;
}
