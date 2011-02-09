use lib '../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;
use 5.010;

use TestHelper;
my $tester = TestHelper->new->generate_test_empire->build_infrastructure;
my $db = Lacuna->db;
my $session_id = $tester->session->id;
my $home_planet = $tester->empire->home_planet_id;
my $empire_id = $tester->empire->id;

diag("session id: $session_id");
diag("home_planet: $home_planet");

my $result = $tester->post('body', 'get_buildable', [$session_id, $home_planet, 3, 3, 'Waste']);

#cmp_ok($result->{result}{buildable}{'Junk Henge Sculpture'}{production}{happiness_hour}, '>=', 0, 'no negative happiness from waste buildings');
#diag(Dumper($result->{result}{buildable}{'Junk Henge Sculpture'}));
#diag(Dumper($result->{result}{buildable}{'Great Ball of Junk'}));
#diag(Dumper($result->{result}{buildable}{'Metal Junk Arches'}));
#diag(Dumper($result->{result}{buildable}{'Pyramid Junk Sculpture'}));
#diag(Dumper($result->{result}{buildable}{'Space Junk Park'}));


my $empire = $db->resultset('Lacuna::DB::Result::Empire')->find($empire_id);
my $home = $empire->home_planet;

$home->waste_capacity(6000000000);
$home->waste_stored(6000000000);
$home->update;

#$db->resultset('Lacuna::DB::Result::Building')->search({class=>'Lacuna::DB::Result::Building::Permanent::JunkHengeSculpture'})->delete; # clean up for future builds
$result = $tester->post('junkhengesculpture', 'build', [$session_id, $home_planet, 1, 1]);
my $junk = $db->resultset('Lacuna::DB::Result::Building')->find($result->{result}{building}{id});
$junk->finish_upgrade;

$home->waste_capacity(600000000);
$home->waste_stored(600000000);
$home->update;

$result = $tester->post('greatballofjunk', 'build', [$session_id, $home_planet, 1, 2]);
my $ball = $db->resultset('Lacuna::DB::Result::Building')->find($result->{result}{building}{id});
$ball->finish_upgrade;

$home->waste_capacity(600000000);
$home->waste_stored(600000000);
$home->update;

$result = $tester->post('metaljunkarches', 'build', [$session_id, $home_planet, 1, 3]);
my $arches = $db->resultset('Lacuna::DB::Result::Building')->find($result->{result}{building}{id});
$arches->finish_upgrade;

$home->waste_capacity(600000000);
$home->waste_stored(600000000);
$home->update;

$result = $tester->post('pyramidjunksculpture', 'build', [$session_id, $home_planet, 1, 4]);
my $pyramid = $db->resultset('Lacuna::DB::Result::Building')->find($result->{result}{building}{id});
$pyramid->finish_upgrade;

$home->waste_capacity(600000000);
$home->waste_stored(600000000);
$home->update;

$result = $tester->post('spacejunkpark', 'build', [$session_id, $home_planet, 1, 5]);
my $space = $db->resultset('Lacuna::DB::Result::Building')->find($result->{result}{building}{id});
$space->finish_upgrade;


END {
	$junk->delete;
	$ball->delete;
	$arches->delete;
	$pyramid->delete;
	$space->delete;
    $tester->cleanup;
}

