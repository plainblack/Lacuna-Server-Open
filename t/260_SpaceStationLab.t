use lib '../lib';
use Test::More tests => 6;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;
use Lacuna::Constants qw(ORE_TYPES);

use TestHelper;
TestHelper->clear_all_test_empires;

my $tester = TestHelper->new->generate_test_empire->build_infrastructure;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;

my $ssla = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
        x               => 4,
        y               => 4,
        class           => 'Lacuna::DB::Result::Building::SSLa',
    });
$home->build_building($ssla);
$ssla->finish_upgrade;
    
my $sslb = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
        x               => 5,
        y               => 4,
        class           => 'Lacuna::DB::Result::Building::SSLb',
    });
$home->build_building($sslb);
$sslb->finish_upgrade;
    
my $sslc = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
        x               => 5,
        y               => 5,
        class           => 'Lacuna::DB::Result::Building::SSLc',
    });
$home->build_building($sslc);
$sslc->finish_upgrade;
    
my $ssld = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
        x               => 4,
        y               => 5,
        class           => 'Lacuna::DB::Result::Building::SSLd',
    });
$home->build_building($ssld);
$ssld->finish_upgrade;
    
my $result;

$result = $tester->post('ssla', 'view', [$session_id, $ssla->id]);
is($result->{result}{make_plan}{subsidy_cost}, 2, 'got subsidy cost');
is(scalar(@{$result->{result}{make_plan}{level_costs}}), 1, 'got level costs');
ok($result->{result}{make_plan}{level_costs}[0]{food} > 1000, 'got good level costs');
ok(exists $result->{result}{make_plan}{types}[0]{url}, 'got types');

$home->ore_capacity(5_000_000);
$home->water_capacity(5_000_000);
$home->food_capacity(5_000_000);
$home->energy_capacity(5_000_000);
foreach my $ore (ORE_TYPES, qw(water algae energy)) {
    $home->add_type($ore, 100_000);
}
$home->update;

$result = $tester->post('ssla', 'make_plan', [$session_id, $ssla->id, 'ibs', 1]);
is($result->{result}{make_plan}{making}, 'Interstellar Broadcast System (1+0)', 'making plan');

$empire->add_essentia({ amount => 10, reason => 'testing'});
$empire->update;

$result = $tester->post('ssla', 'subsidize_plan', [$session_id, $ssla->id]);
ok(!exists $result->{result}{make_plan}{making}, 'subsidize making plan');



END {
    TestHelper->clear_all_test_empires;
}
